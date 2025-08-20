#!/usr/bin/env python3
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import os
import stripe
from datetime import datetime
import sqlite3

app = Flask(__name__)
CORS(app)

# 环境变量
STRIPE_SECRET_KEY = os.environ.get('STRIPE_SECRET_KEY', 'sk_test_51PytZfCdh5c7XDJbzyKGKaM1gQ4ZmHv7fl0KbUd3htuQtc2xhjuAYmyntiFnfbrOvxUstg4QieVEBvVjFlb9lHhp0071q2E9Sm')
STRIPE_PUBLISHABLE_KEY = os.environ.get('STRIPE_PUBLISHABLE_KEY', 'pk_test_51PytZfCdh5c7XDJbxFrbSaZX55doWLbrZ77iutZTR8vlrQcogvQJSFNWkH4fJbqDzZo551D2ZSsw6dqFvQt9btrc00C0B2mrqr')

stripe.api_key = STRIPE_SECRET_KEY

DATABASE = 'production.db'

def get_db():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

# 根路径 - 解决Render 404
@app.route('/')
def index():
    """根路径健康检查"""
    return jsonify({
        "status": "healthy",
        "service": "HopeHub API",
        "message": "Welcome to HopeHub - Your Exclusive Business Position Platform",
        "version": "2.1",
        "endpoints": {
            "health": "/api/health",
            "positions": "/api/positions",
            "stripe_config": "/api/stripe_config",
            "create_payment": "/api/create_payment",
            "login": "/api/login",
            "register": "/api/register"
        }
    })

@app.route('/api/health')
def health():
    """健康检查端点"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "HopeHub API",
        "version": "2.1",
        "database": "connected" if check_db() else "error"
    })

def check_db():
    """检查数据库连接"""
    try:
        conn = get_db()
        conn.execute('SELECT 1')
        conn.close()
        return True
    except:
        return False

@app.route('/api/positions')
def get_positions():
    """获取位置列表"""
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM positions_v2 LIMIT 20')
        positions = [dict(row) for row in cursor.fetchall()]
        conn.close()
        return jsonify(positions)
    except:
        # 返回示例数据
        positions = [
            {"id": 1, "zip_code": "10001", "industry": "Tech", "price": 100, "status": "available"},
            {"id": 2, "zip_code": "10002", "industry": "Retail", "price": 80, "status": "available"},
            {"id": 3, "zip_code": "94102", "industry": "Finance", "price": 150, "status": "available"}
        ]
        return jsonify(positions)

@app.route('/api/stripe_config')
def stripe_config():
    """获取Stripe配置"""
    return jsonify({
        "publishable_key": STRIPE_PUBLISHABLE_KEY,
        "configured": True
    })

@app.route('/api/create_payment', methods=['POST'])
def create_payment():
    """创建支付会话"""
    try:
        data = request.json or {}
        amount = data.get('amount', 10)
        position_id = data.get('position_id', 1)
        
        # 创建Stripe会话
        session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[{
                'price_data': {
                    'currency': 'usd',
                    'product_data': {
                        'name': f'HopeHub Position #{position_id}',
                        'description': 'Exclusive business position'
                    },
                    'unit_amount': amount * 100,  # Stripe使用分为单位
                },
                'quantity': 1,
            }],
            mode='payment',
            success_url='https://hopehub.x1000.ai/payment_success.html?session_id={CHECKOUT_SESSION_ID}',
            cancel_url='https://hopehub.x1000.ai/payment_cancel.html',
        )
        
        return jsonify({
            'success': True,
            'session_id': session.id,
            'checkout_url': session.url
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400

@app.route('/api/login', methods=['POST'])
def login():
    """用户登录"""
    data = request.json or {}
    email = data.get('email', '')
    
    # 模拟登录成功
    return jsonify({
        "success": True,
        "user": {
            "id": 1,
            "email": email,
            "username": email.split('@')[0],
            "points": 1000
        }
    })

@app.route('/api/register', methods=['POST'])
def register():
    """用户注册"""
    data = request.json or {}
    return jsonify({
        "success": True,
        "message": "Registration successful"
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
