# Go to project root
cd /home/ubuntu/playground/KhuChinQue-Framework

# Check Docker status
systemctl is-active docker || sudo systemctl start docker

# Check compose file
docker-compose config > /dev/null && echo "✅ docker-compose.yml is valid"
