#!/bin/bash
# SilverConnect - PythonAnywhere Auto Setup Script
# Run this from the PythonAnywhere Bash console

set -e

USERNAME=$(whoami)
echo "=== SilverConnect Deployment for $USERNAME ==="

# 1. Clone repo
cd ~
rm -rf silverconnect
git clone https://github.com/avishalva2004-coder/silverconnect.git
cd silverconnect

# 2. Create virtualenv
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install --upgrade pip
pip install flask flask-bcrypt flask-cors pymysql cryptography
pip install gunicorn

# 4. Create MySQL database and run schema
PASSWORD=$(openssl rand -base64 12)
mysql -u $USERNAME -h$USERNAME.mysql.pythonanywhere-services.com -e "CREATE DATABASE IF NOT EXISTS $USERNAME\$silverconnect;"
mysql -u $USERNAME -h$USERNAME.mysql.pythonanywhere-services.com $USERNAME\$silverconnect < schema.sql

# 5. Create .env file with DB credentials
cat > .env << EOF
DB_HOST=$USERNAME.mysql.pythonanywhere-services.com
DB_USER=$USERNAME
DB_PASSWORD=
DB_NAME=$USERNAME\$silverconnect
SECRET_KEY=$(openssl rand -hex 24)
EOF

echo "SECRET_KEY=$(openssl rand -hex 24)" >> .env

# 6. Update app.py to read DB config from environment
echo ""
echo "=== Setup complete! ==="
echo ""
echo "NEXT STEPS:"
echo "1. Go to Web tab → Add a new web app → Manual Configuration → Python 3.12"
echo "2. Set:"
echo "   Source code: /home/$USERNAME/silverconnect"
echo "   Working directory: /home/$USERNAME/silverconnect"
echo "   Virtualenv: /home/$USERNAME/silverconnect/venv"
echo "3. Edit WSGI configuration file and replace with:"
echo ""
echo "---------------------------------------------------"
echo "import sys"
echo "import os"
echo "os.environ['DB_HOST'] = '$USERNAME.mysql.pythonanywhere-services.com'"
echo "os.environ['DB_USER'] = '$USERNAME'"
echo "os.environ['DB_PASSWORD'] = ''"
echo "os.environ['DB_NAME'] = '$USERNAME\$silverconnect'"
echo "os.environ['SECRET_KEY'] = '$(openssl rand -hex 24)'"
echo ""
echo "path = '/home/$USERNAME/silverconnect'"
echo "if path not in sys.path:"
echo "    sys.path.append(path)"
echo ""
echo "from app import app as application"
echo "---------------------------------------------------"
echo ""
echo "4. Go to Web tab → Reload"
echo "5. Open https://$USERNAME.pythonanywhere.com"
