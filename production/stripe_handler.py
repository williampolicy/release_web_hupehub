#!/usr/bin/env python3
"""
Stripe支付处理器 - Phase 7
简单、直接、能用
"""

import stripe
from flask import jsonify, request
import os
from datetime import datetime

# Stripe配置（测试密钥）
stripe.api_key = os.getenv('STRIPE_SECRET_KEY', 'sk_test_YOUR_TEST_KEY')
STRIPE_PUBLISHABLE_KEY = os.getenv('STRIPE_PUBLISHABLE_KEY', 'pk_test_YOUR_TEST_KEY')

class StripeHandler:
    """Stripe支付处理器"""
    
    def __init__(self):
        self.currency = 'usd'
        self.success_url = 'http://localhost:8000/payment_success.html'
        self.cancel_url = 'http://localhost:8000/payment_cancel.html'
    
    def create_checkout_session(self, user_id, position_id, amount):
        """创建Stripe Checkout会话"""
        try:
            # 创建Checkout Session
            session = stripe.checkout.Session.create(
                payment_method_types=['card'],
                line_items=[{
                    'price_data': {
                        'currency': self.currency,
                        'product_data': {
                            'name': f'HopeHub Position #{position_id}',
                            'description': f'独家位置购买 - 用户{user_id}',
                        },
                        'unit_amount': int(amount * 100),  # Stripe使用分为单位
                    },
                    'quantity': 1,
                }],
                mode='payment',
                success_url=self.success_url + '?session_id={CHECKOUT_SESSION_ID}',
                cancel_url=self.cancel_url,
                metadata={
                    'user_id': str(user_id),
                    'position_id': str(position_id)
                }
            )
            
            return {
                'success': True,
                'session_id': session.id,
                'checkout_url': session.url
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def verify_payment(self, session_id):
        """验证支付是否成功"""
        try:
            session = stripe.checkout.Session.retrieve(session_id)
            
            if session.payment_status == 'paid':
                return {
                    'success': True,
                    'paid': True,
                    'metadata': session.metadata
                }
            else:
                return {
                    'success': True,
                    'paid': False
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def create_payment_intent(self, amount, metadata=None):
        """创建Payment Intent（备用方法）"""
        try:
            intent = stripe.PaymentIntent.create(
                amount=int(amount * 100),
                currency=self.currency,
                metadata=metadata or {}
            )
            
            return {
                'success': True,
                'client_secret': intent.client_secret,
                'intent_id': intent.id
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

# 单例模式
stripe_handler = StripeHandler()
