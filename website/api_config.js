// HopeHub API配置
const API_URL = 'https://release-web-hupehub.onrender.com';

// 获取Stripe配置
async function getStripeConfig() {
    const response = await fetch(`${API_URL}/api/stripe_config`);
    const data = await response.json();
    return data.publishable_key;
}

// API调用封装
const api = {
    // 获取位置列表
    async getPositions() {
        const response = await fetch(`${API_URL}/api/positions`);
        return await response.json();
    },
    
    // 用户登录
    async login(email, password) {
        const response = await fetch(`${API_URL}/api/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });
        return await response.json();
    },
    
    // 创建支付
    async createPayment(amount, positionId) {
        const response = await fetch(`${API_URL}/api/create_payment`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount, position_id: positionId })
        });
        return await response.json();
    }
};
