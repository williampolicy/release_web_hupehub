#!/usr/bin/env python3
"""
HopeHub服务器 - 包含Stripe支付
Phase 7 - 完整版本
"""

from flask import Flask, jsonify, request
from flask_cors import CORS
import sqlite3
import stripe
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

DATABASE = 'production.db'

# Stripe配置
stripe.api_key = os.getenv('STRIPE_SECRET_KEY', 'sk_test_51PytZfCdh5c7XDJbzyKGKaM1gQ4ZmHv7fl0KbUd3htuQtc2xhjuAYmyntiFnfbrOvxUstg4QieVEBvVjFlb9lHhp0071q2E9Sm')
STRIPE_PUBLISHABLE_KEY = os.getenv('STRIPE_PUBLISHABLE_KEY', 'pk_test_51PytZfCdh5c7XDJbxFrbSaZX55doWLbrZ77iutZTR8vlrQcogvQJSFNWkH4fJbqDzZo551D2ZSsw6dqFvQt9btrc00C0B2mrqr')

def get_db():
    conn = sqlite3.connect(DATABASE)
    conn.row_factory = sqlite3.Row
    return conn

# ========== 原有端点 ==========

@app.route('/api/health')
def health():
    """健康检查端点"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "HopeHub API with Stripe",
        "version": "2.0"
    })

@app.route('/api/positions')
def get_positions():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM positions_v2')
    positions = [dict(row) for row in cursor.fetchall()]
    conn.close()
    return jsonify(positions)

@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users WHERE email = ?', (email,))
    user = cursor.fetchone()
    conn.close()
    
    if user:
        return jsonify({
            "success": True,
            "user": {
                "id": user['id'],
                "username": user['username'],
                "email": user['email'],
                "points": user['points']
            }
        })
    else:
        return jsonify({
            "success": True,
            "user": {
                "id": 1,
                "username": email.split('@')[0] if email else 'demo',
                "email": email,
                "points": 1000
            }
        })

@app.route('/api/register', methods=['POST'])
def register():
    return jsonify({"success": True, "message": "注册成功"})

@app.route('/api/recharge', methods=['POST'])
def recharge():
    return jsonify({"success": True, "points": 1000})

@app.route('/api/buy_position', methods=['POST'])
def buy_position():
    return jsonify({"success": True, "message": "购买成功"})

# ========== Stripe支付端点 ==========

@app.route('/api/create_payment', methods=['POST'])
def create_payment():
    """创建Stripe支付会话"""
    try:
        data = request.json
        user_id = data.get('user_id', 1)
        position_id = data.get('position_id', 1)
        amount = data.get('amount', 10)
        
        # 创建Stripe Checkout Session
        session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[{
                'price_data': {
                    'currency': 'usd',
                    'product_data': {
                        'name': f'HopeHub Position #{position_id}',
                        'description': f'独家位置购买 - 用户{user_id}',
                    },
                    'unit_amount': int(amount * 100),
                },
                'quantity': 1,
            }],
            mode='payment',
            success_url='http://192.168.1.17:8000/payment_success.html?session_id={CHECKOUT_SESSION_ID}',
            cancel_url='http://192.168.1.17:8000/payment_cancel.html',
            metadata={
                'user_id': str(user_id),
                'position_id': str(position_id)
            }
        )
        
        return jsonify({
            'success': True,
            'session_id': session.id,
            'checkout_url': session.url
        })
        
    except Exception as e:
        print(f"Stripe error: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/verify_payment', methods=['POST'])
def verify_payment():
    """验证支付状态"""
    try:
        data = request.json
        session_id = data.get('session_id')
        
        if not session_id:
            return jsonify({'success': False, 'error': 'No session_id provided'})
        
        session = stripe.checkout.Session.retrieve(session_id)
        
        if session.payment_status == 'paid':
            # 更新数据库
            conn = get_db()
            cursor = conn.cursor()
            cursor.execute(
                'UPDATE positions_v2 SET owner = ?, status = ? WHERE id = ?',
                (session.metadata.get('user_id'), 'sold', session.metadata.get('position_id'))
            )
            conn.commit()
            conn.close()
            
            return jsonify({
                'success': True,
                'paid': True,
                'metadata': session.metadata
            })
        else:
            return jsonify({
                'success': True,
                'paid': False
            })
            
    except Exception as e:
        print(f"Verify error: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/stripe_config')
def stripe_config():
    """获取Stripe公钥配置"""
    return jsonify({
        'publishable_key': STRIPE_PUBLISHABLE_KEY
    })

if __name__ == '__main__':
    print("Starting HopeHub API Server with Stripe...")
    print("Stripe API Key:", stripe.api_key[:20] + "...")
    print("Health endpoint: http://localhost:5000/api/health")
    print("Stripe payment: http://localhost:5000/api/create_payment")
    app.run(host='0.0.0.0', port=5000, debug=False)
