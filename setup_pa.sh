#!/bin/bash
# SilverConnect - PythonAnywhere Auto Setup Script (SQLite)
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
pip install flask flask-bcrypt cryptography
pip install gunicorn

# 4. Initialize SQLite database
python3 -c "
import os, sys
os.chdir(os.path.dirname(__file__) or '.')
from app import init_db
init_db()
print('DB initialized at', os.path.join(os.path.dirname(__file__), 'silverconnect.db'))
"

# 5. Create .env file
cat > .env << EOF
SECRET_KEY=$(openssl rand -hex 24)
EOF

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
