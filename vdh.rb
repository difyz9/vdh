class Vdh < Formula
  desc "Video downloader helper with Unix socket and queue management"
  homepage "https://github.com/difyz9/vdh"
  url "file:///Users/apple/opt/difyz_08/git003/0831/socket_demo/helper_tool"
  version "1.0.0"
  license "MIT"

  depends_on "swift"
  depends_on "yt-dlp"

  def install
    # 编译 Swift 源码
    system "swiftc", "main.swift", "-o", "vdh"
    
    # 安装二进制文件
    bin.install "vdh"
    
    # 安装配置文件
    (etc/"vdh").mkpath
    (etc/"vdh/config.json").write config_template
    
    # 安装 launchd plist 文件
    (prefix/"LaunchDaemons").mkpath
    (prefix/"LaunchDaemons/com.vdh.helper.plist").write launchd_plist
    
    # 安装日志目录
    (var/"log/vdh").mkpath
  end

  def config_template
    <<~EOS
    {
      "max_concurrent_downloads": 2,
      "socket_path": "/tmp/video_downloader.sock",
      "download_directory": "#{Dir.home}/Downloads/VideoDownloader",
      "proxy": "http://127.0.0.1:7890",
      "log_level": "info"
    }
    EOS
  end

  def launchd_plist
    <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>com.videodownloader.helper</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{bin}/vdh</string>
        <string>server</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <true/>
      <key>StandardOutPath</key>
      <string>#{var}/log/vdh/output.log</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/vdh/error.log</string>
      <key>WorkingDirectory</key>
      <string>#{bin}</string>
    </dict>
    </plist>
    EOS
  end

  service do
    run [opt_bin/"vdh", "server"]
    keep_alive true
    log_path var/"log/vdh/output.log"
    error_log_path var/"log/vdh/error.log"
  end

  test do
    system "#{bin}/vdh", "--help"
  end

  def caveats
    <<~EOS
    To start the VDH (Video Downloader Helper) service:
      brew services start vdh
      
    To stop the service:
      brew services stop vdh
      
    To check service status:
      brew services list | grep vdh
      
    To check download queue status:
      vdh status
      
    To send a download request:
      vdh send "https://youtube.com/watch?v=..."
      
    Configuration file is located at:
      #{etc}/vdh/config.json
      
    Logs are available at:
      #{var}/log/vdh/
    EOS
  end
end
