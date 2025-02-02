#!/bin/bash
echo "更新系统。。。"
sudo apt update && sudo apt upgrade -y

echo "下载 ZABBIX AGENT..."
url="https://repo.zabbix.com/zabbix/7.2/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.2+ubuntu22.04_all.deb"
output_file="zabbix-release_latest_7.2+ubuntu22.04_all.deb"

# 最大重试次数
max_retries=5

for ((i=1; i<=max_retries; i++)); do
  echo "尝试第 $i 次下载..."
  wget -O "$output_file" "$url" && break
  echo "下载失败，等待 3 秒后重试..."
  sleep 3
done

if [[ ! -f "$output_file" ]]; then
  echo "下载失败，超过最大重试次数 $max_retries 次，请检查网络或 URL。"
  exit 1
fi
echo "下载成功！"

echo "安装 ZABBIX AGENT..."
sudo dpkg -i zabbix-release_latest_7.2+ubuntu22.04_all.deb
sudo apt update && sudo apt install zabbix-agent -y

echo "开放端口 10050"
sudo ufw allow 10050/tcp
echo "编辑配置文件"

# 配置文件路径
CONFIG_FILE="/etc/zabbix/zabbix_agentd.conf"

# 需要替换的内容
NEW_SERVER="192.168.9.68"
NEW_ACTIVE_SERVER="192.168.9.68"

# 替换 Server 和 ActiveServer 的值
sudo sed -i "s/^Server=.*/Server=$NEW_SERVER/" "$CONFIG_FILE"
sudo sed -i "s/^ActiveServer=.*/ActiveServer=$NEW_ACTIVE_SERVER/" "$CONFIG_FILE"

sudo echo "AllowKey=log[*]" | sudo tee -a "$CONFIG_FILE"
sudo echo "UserParameter=log.monitor,/usr/bin/tail -n100 /home/account1/poly-ubuntu-v1.1/logs/crypto_trader.log | grep -E \"ERROR|未登录\"" | sudo tee -a "$CONFIG_FILE"

# 验证修改结果
sudo echo "Updated configuration:"
grep -E "^(Server|ActiveServer)=" "$CONFIG_FILE"

sudo chown zabbix:zabbix /home/account1/poly-ubuntu-v1.1/logs/crypto_trader.log
sudo chmod 644 /home/account1/poly-ubuntu-v1.1/logs/crypto_trader.log

echo "设置自启动。。。"
sudo systemctl start zabbix-agent
sudo systemctl enable zabbix-agent
sudo systemctl status zabbix-agent
