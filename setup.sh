#!/bin/bash

# VidStream Setup Script
echo "================================"
echo "VidStream Setup Script"
echo "================================"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.8 or higher."
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Check if MySQL is installed
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL is not installed. Please install MySQL Server 5.7 or higher."
    exit 1
fi

echo "✅ MySQL found"

# Install Python dependencies
echo ""
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "❌ Failed to install Python dependencies."
    exit 1
fi

echo "✅ Python dependencies installed"

# Create upload directory
echo ""
echo "📁 Creating upload directory..."
mkdir -p static/uploads
chmod 755 static/uploads
echo "✅ Upload directory created"

# Database setup
echo ""
echo "🗄️  Setting up MySQL database..."
read -p "Enter MySQL root password: " -s mysql_password
echo ""

# Create database
mysql -u root -p"$mysql_password" -e "CREATE DATABASE IF NOT EXISTS youtube_app;" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Failed to create database. Please check your MySQL password."
    exit 1
fi

echo "✅ Database created"

# Import schema
echo "📊 Importing database schema..."
mysql -u root -p"$mysql_password" youtube_app < schema.sql 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Failed to import schema."
    exit 1
fi

echo "✅ Schema imported"

# Update app.py with password
echo ""
echo "🔧 Configuring database connection..."
read -p "Do you want to update the database password in app.py? (y/n): " update_config

if [ "$update_config" = "y" ] || [ "$update_config" = "Y" ]; then
    # Create a backup
    cp app.py app.py.backup
    
    # Update password in app.py (basic sed command)
    echo "Please manually update the DB_CONFIG password in app.py (line ~16)"
    echo "Set 'password': '$mysql_password'"
fi

echo ""
echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo ""
echo "Default admin credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "To start the application:"
echo "  python3 app.py"
echo ""
echo "Then visit: http://localhost:5000"
echo ""
echo "⚠️  Don't forget to update the MySQL password in app.py!"
echo "================================"
