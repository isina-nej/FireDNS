#include "flutter_window.h"

#include <optional>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <thread>
#include <regex>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  // Add MethodChannel for DNS
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "com.example.firedns/dns",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name().compare("testDnsIPv6") == 0) {
          const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
          std::string dns = "";
          if (arguments && arguments->find(flutter::EncodableValue("dns")) != arguments->end()) {
            dns = std::get<std::string>(arguments->at(flutter::EncodableValue("dns")));
          }
          if (dns.empty()) {
            result->Error("INVALID_DNS", "DNS address cannot be empty");
            return;
          }
          // Run ping -6 command in a thread
          std::thread([dns, res = std::move(result)]() mutable {
            std::string command = "ping -6 -n 2 -w 1000 " + dns;
            FILE* pipe = _popen(command.c_str(), "r");
            if (!pipe) {
              res->Error("PING_ERROR", "Failed to run ping command");
              return;
            }
            char buffer[256];
            std::string ping_output = "";
            while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
              ping_output += buffer;
            }
            _pclose(pipe);

            bool isReachable = ping_output.find("TTL=") != std::string::npos;
            int pingTime = -1;
            std::smatch match;
            std::regex ping_regex("time=([0-9]+)ms");
            if (std::regex_search(ping_output, match, ping_regex)) {
              pingTime = std::stoi(match[1]);
            }
            flutter::EncodableMap result_map = {
              {flutter::EncodableValue("isReachable"), flutter::EncodableValue(isReachable)},
              {flutter::EncodableValue("ping"), flutter::EncodableValue(pingTime)}
            };
            res->Success(flutter::EncodableValue(result_map));
          }).detach();
          return;
        }
        result->NotImplemented();
      });
  // Keep channel alive
  static auto s_channel = std::move(channel);

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
