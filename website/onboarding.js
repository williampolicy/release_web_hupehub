// 新手引导系统
class UserOnboarding {
    constructor() {
        this.currentStep = 0;
        this.steps = [
            {
                element: '#zipInput',
                title: '欢迎来到HopeHub！',
                content: '首先，输入您的ZIP CODE来定位您的商业区域',
                position: 'bottom'
            },
            {
                element: '.hot-zips-grid',
                title: '快速选择',
                content: '您也可以点击这些热门地区快速开始',
                position: 'top'
            },
            {
                element: '.industries-grid',
                title: '选择您的行业',
                content: '每个行业在每个ZIP区域都是独一无二的',
                position: 'top'
            }
        ];
    }
    
    start() {
        // 检查是否是新用户
        if (localStorage.getItem('onboarding_completed')) {
            return;
        }
        
        this.showStep(0);
    }
    
    showStep(index) {
        if (index >= this.steps.length) {
            this.complete();
            return;
        }
        
        const step = this.steps[index];
        this.createTooltip(step);
    }
    
    createTooltip(step) {
        // 创建引导提示
        const tooltip = document.createElement('div');
        tooltip.className = 'onboarding-tooltip';
        tooltip.innerHTML = `
            <div class="onboarding-title">${step.title}</div>
            <div class="onboarding-content">${step.content}</div>
            <div class="onboarding-actions">
                <button onclick="onboarding.skip()">跳过</button>
                <button onclick="onboarding.next()" class="primary">下一步</button>
            </div>
        `;
        
        // 定位提示
        const element = document.querySelector(step.element);
        if (element) {
            const rect = element.getBoundingClientRect();
            tooltip.style.position = 'fixed';
            
            if (step.position === 'bottom') {
                tooltip.style.top = (rect.bottom + 10) + 'px';
                tooltip.style.left = rect.left + 'px';
            } else {
                tooltip.style.top = (rect.top - 100) + 'px';
                tooltip.style.left = rect.left + 'px';
            }
        }
        
        document.body.appendChild(tooltip);
    }
    
    next() {
        // 移除当前提示
        const current = document.querySelector('.onboarding-tooltip');
        if (current) current.remove();
        
        // 显示下一步
        this.currentStep++;
        this.showStep(this.currentStep);
    }
    
    skip() {
        const current = document.querySelector('.onboarding-tooltip');
        if (current) current.remove();
        this.complete();
    }
    
    complete() {
        localStorage.setItem('onboarding_completed', 'true');
        console.log('新手引导完成');
    }
}

// 自动启动引导
const onboarding = new UserOnboarding();
// window.addEventListener('load', () => onboarding.start());
