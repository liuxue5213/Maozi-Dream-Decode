/**
 * 梦语 Web 应用
 * 梦境记录与 AI 解析
 */

const API_BASE = '/api/v1';
let currentToken = localStorage.getItem('dream_token') || null;
let currentUser = JSON.parse(localStorage.getItem('dream_user') || 'null');

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

function renderPlainMarkdown(value) {
    return escapeHtml(value)
        .replace(/^### (.*)$/gm, '<h4>$1</h4>')
        .replace(/^## (.*)$/gm, '<h3>$1</h3>')
        .replace(/^# (.*)$/gm, '<h2>$1</h2>')
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\n/g, '<br>');
}

// ===== API 请求 =====

async function apiRequest(endpoint, options = {}) {
    const url = `${API_BASE}${endpoint}`;
    const config = {
        headers: { ...options.headers },
        ...options,
    };
    
    // 只在有 body 时设置 Content-Type
    if (config.body && typeof config.body === 'object') {
        config.headers['Content-Type'] = 'application/json';
        config.body = JSON.stringify(config.body);
    }
    
    if (currentToken) {
        config.headers['Authorization'] = `Bearer ${currentToken}`;
    }
    
    try {
        const response = await fetch(url, config);
        
        // 尝试解析 JSON，如果失败则返回文本
        let data;
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
            data = await response.json();
        } else {
            data = await response.text();
        }
        
        if (!response.ok) {
            const message = typeof data === 'object' ? data.detail : data;
            throw new Error(message || `请求失败 (${response.status})`);
        }
        
        return data;
    } catch (error) {
        if (error.message.includes('401')) {
            logout();
            showToast('登录已过期，请重新登录', 'error');
        }
        throw error;
    }
}

// ===== 提示 =====

function showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast ${type}`;
    setTimeout(() => {
        toast.classList.add('hidden');
    }, 3000);
}

// ===== 认证 =====

function setAuth(token, user) {
    currentToken = token;
    currentUser = user;
    localStorage.setItem('dream_token', token);
    localStorage.setItem('dream_user', JSON.stringify(user));
}

function logout() {
    currentToken = null;
    currentUser = null;
    localStorage.removeItem('dream_token');
    localStorage.removeItem('dream_user');
    showAuthPage();
}

function showAuthPage() {
    document.getElementById('auth-page').classList.remove('hidden');
    document.getElementById('main-page').classList.add('hidden');
}

function showMainPage() {
    document.getElementById('auth-page').classList.add('hidden');
    document.getElementById('main-page').classList.remove('hidden');
    document.getElementById('user-info').textContent = currentUser?.nickname || '梦友';
    showSection('dreams-section');
    loadDreams();
}

// ===== 页面切换 =====

function showSection(sectionId) {
    // 隐藏所有 section
    document.querySelectorAll('.content-section').forEach(s => s.classList.add('hidden'));
    // 显示目标 section
    document.getElementById(sectionId).classList.remove('hidden');
    
    // 更新底部导航
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.dataset.section === sectionId);
    });
    
    // 加载对应数据
    if (sectionId === 'dreams-section') loadDreams();
    if (sectionId === 'encyclopedia-section') loadEncyclopedia();
}

// ===== 梦境列表 =====

async function loadDreams() {
    const container = document.getElementById('dreams-list');
    container.innerHTML = '<div class="loading">加载中...</div>';
    
    try {
        const dreams = await apiRequest('/dreams');
        
        if (dreams.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <span class="empty-icon">💭</span>
                    <p>还没有记录过梦境</p>
                    <p class="empty-hint">点击「记梦」开始记录你的第一个梦</p>
                </div>
            `;
            return;
        }
        
        container.innerHTML = dreams.map(dream => `
            <div class="dream-card" onclick="showInterpretation(${dream.id})">
                <div class="dream-card-header">
                    <span class="dream-card-date">${dream.dream_date}</span>
                </div>
                <div class="dream-card-content">${escapeHtml(dream.content)}</div>
                ${dream.emotion_tags?.length ? `
                    <div class="dream-card-tags">
                        ${dream.emotion_tags.map(t => `<span class="dream-tag">${escapeHtml(t)}</span>`).join('')}
                    </div>
                ` : ''}
            </div>
        `).join('');
    } catch (error) {
        container.innerHTML = `<div class="empty-state"><p>加载失败: ${error.message}</p></div>`;
    }
}

// ===== 记录梦境 =====

async function saveDream(formData) {
    try {
        const dream = await apiRequest('/dreams', {
            method: 'POST',
            body: formData,
        });
        showToast('梦境已保存', 'success');
        
        // 尝试自动解析（解析失败不影响保存成功）
        try {
            showToast('正在进行 AI 解析...', 'info');
            await apiRequest(`/dreams/${dream.id}/interpretations`, { method: 'POST' });
            showToast('解析完成！', 'success');
        } catch (interpError) {
            showToast('已保存，AI 解析暂不可用，可在详情页手动解析', 'info');
        }
        
        showInterpretation(dream.id);
        return dream;
    } catch (error) {
        showToast(error.message, 'error');
        throw error;
    }
}

// ===== 解析结果 =====

let currentDreamId = null;

async function showInterpretation(dreamId) {
    currentDreamId = dreamId;
    showSection('interpretation-section');
    const container = document.getElementById('interpretation-content');
    container.innerHTML = '<div class="loading">正在加载解析结果...</div>';
    
    try {
        // 获取梦境详情
        const dream = await apiRequest(`/dreams/${dreamId}`);
        
        // 获取解析结果列表
        const interpretations = await apiRequest(`/dreams/${dreamId}/interpretations`);
        
        if (interpretations.length === 0) {
            // 没有解析结果，显示提示
            container.innerHTML = `
                <div class="interpretation-item">
                    <h4>📝 梦境内容</h4>
                    <p>${dream.content}</p>
                </div>
                <div class="empty-state">
                    <p>暂无解析结果</p>
                    <button class="btn-primary" onclick="createInterpretation(${dreamId})" style="margin-top: 16px; width: auto;">
                        立即解析
                    </button>
                </div>
            `;
            return;
        }
        
        // 显示最新的解析结果
        const result = interpretations[0].result_json;
        if (result && result.content) {
            container.innerHTML = `
                <div class="interpretation-item"><h4>📝 梦境内容</h4><p>${escapeHtml(dream.content)}</p></div>
                <div class="interpretation-item markdown-result">${renderPlainMarkdown(result.content)}</div>
                <div class="disclaimer">⚠️ AI 解析仅供参考，不构成医疗或心理治疗建议。</div>`;
            return;
        }
        const symbols = result.symbols || [];
        const suggestions = result.suggestions || [];
        
        container.innerHTML = `
            <div class="interpretation-item">
                <h4>📝 梦境内容</h4>
                <p>${escapeHtml(dream.content)}</p>
            </div>
            ${dream.emotion_tags?.length ? `
                <div class="interpretation-item">
                    <h4>🎭 情绪标签</h4>
                    <p>${dream.emotion_tags.map(escapeHtml).join('、')}</p>
                </div>
            ` : ''}
            
            <div class="interpretation-item">
                <h4>💡 梦境主题</h4>
                <p>${escapeHtml(result.summary || '暂无')}</p>
            </div>
            
            ${symbols.length ? `
                <div class="interpretation-item">
                    <h4>🔮 象征元素</h4>
                    ${symbols.map(s => `
                        <div class="symbol-item">
                            <span class="symbol-label">${escapeHtml(s.element)}</span>
                            <div>
                                ${s.traditional_meaning ? `<p><strong>传统：</strong>${escapeHtml(s.traditional_meaning)}</p>` : ''}
                                ${s.psychology_meaning ? `<p><strong>心理：</strong>${escapeHtml(s.psychology_meaning)}</p>` : ''}
                                ${s.culture_meaning ? `<p><strong>文化：</strong>${escapeHtml(s.culture_meaning)}</p>` : ''}
                            </div>
                        </div>
                    `).join('')}
                </div>
            ` : ''}
            
            ${result.psychology_analysis ? `
                <div class="interpretation-item">
                    <h4>🧠 心理学视角</h4>
                <p>${escapeHtml(result.psychology_analysis)}</p>
                </div>
            ` : ''}
            
            ${result.traditional_meaning ? `
                <div class="interpretation-item">
                    <h4>📜 传统解梦</h4>
                <p>${escapeHtml(result.traditional_meaning)}</p>
                </div>
            ` : ''}
            
            ${result.reality_connection ? `
                <div class="interpretation-item">
                    <h4>🔗 现实关联</h4>
                <p>${escapeHtml(result.reality_connection)}</p>
                </div>
            ` : ''}
            
            ${suggestions.length ? `
                <div class="interpretation-item">
                    <h4>✨ 自我觉察建议</h4>
                    <ol style="padding-left: 20px;">
                        ${suggestions.map(s => `<li style="margin-bottom: 8px; line-height: 1.6;">${escapeHtml(s)}</li>`).join('')}
                    </ol>
                </div>
            ` : ''}
            
            <div class="disclaimer">
                ⚠️ ${escapeHtml(result.disclaimer || '本解析由 AI 生成，仅供参考，不构成医疗或心理治疗建议。如有严重心理困扰，请寻求专业心理咨询师帮助。')}
            </div>
        `;
    } catch (error) {
        container.innerHTML = `<div class="empty-state"><p>加载失败: ${error.message}</p></div>`;
    }
}

async function createInterpretation(dreamId) {
    showToast('正在解析，请稍候...');
    try {
        await apiRequest(`/dreams/${dreamId}/interpretations`, { method: 'POST' });
        showToast('解析完成！', 'success');
        showInterpretation(dreamId);
    } catch (error) {
        showToast(error.message, 'error');
    }
}

async function regenerateInterpretation() {
    if (!currentDreamId) return;
    showToast('正在重新生成...');
    
    try {
        const result = await apiRequest(`/dreams/${currentDreamId}/interpretations/regenerate`, {
            method: 'POST',
        });
        showToast('已重新生成', 'success');
        showInterpretation(currentDreamId);
    } catch (error) {
        showToast(error.message, 'error');
    }
}

// ===== 百科 =====

let encyclopediaData = [];

async function loadEncyclopedia() {
    const container = document.getElementById('encyclopedia-list');
    container.innerHTML = '<div class="loading">加载中...</div>';
    
    try {
        const result = await apiRequest('/encyclopedia?page_size=100');
        encyclopediaData = result;
        filterEncyclopedia();
    } catch (error) {
        container.innerHTML = `<div class="empty-state"><p>加载失败: ${error.message}</p></div>`;
    }
}

function filterEncyclopedia() {
    const keyword = document.getElementById('encyclopedia-search').value.trim().toLowerCase();
    const activeCategory = document.querySelector('.category-tag.active')?.dataset.value || '';
    
    let filtered = encyclopediaData;
    
    if (activeCategory) {
        filtered = filtered.filter(item => item.category === activeCategory);
    }
    
    if (keyword) {
        filtered = filtered.filter(item => 
            item.title.toLowerCase().includes(keyword) ||
            (item.traditional_meaning && item.traditional_meaning.includes(keyword)) ||
            (item.psychology_meaning && item.psychology_meaning.includes(keyword))
        );
    }
    
    const container = document.getElementById('encyclopedia-list');
    
    if (filtered.length === 0) {
        container.innerHTML = '<div class="empty-state"><p>没有找到相关词条</p></div>';
        return;
    }
    
    container.innerHTML = filtered.map(item => `
        <div class="encyclopedia-item" onclick="showItemDetail(${item.id})">
            <h4>${item.title}</h4>
            <p>${item.category}</p>
        </div>
    `).join('');
}

function showItemDetail(itemId) {
    const item = encyclopediaData.find(i => i.id === itemId);
    if (!item) return;
    
    document.getElementById('modal-title').textContent = item.title;
    document.getElementById('modal-body').innerHTML = `
        ${item.traditional_meaning ? `
            <div class="meaning-section">
                <h5>📜 传统解梦</h5>
                <p>${item.traditional_meaning}</p>
            </div>
        ` : ''}
        ${item.psychology_meaning ? `
            <div class="meaning-section">
                <h5>🧠 心理学解释</h5>
                <p>${item.psychology_meaning}</p>
            </div>
        ` : ''}
        ${item.culture_meaning ? `
            <div class="meaning-section">
                <h5>🌍 文化象征</h5>
                <p>${item.culture_meaning}</p>
            </div>
        ` : ''}
        ${item.advice ? `
            <div class="meaning-section">
                <h5>💡 自我觉察建议</h5>
                <p>${item.advice}</p>
            </div>
        ` : ''}
        ${item.source ? `
            <div class="meaning-section">
                <h5>📖 来源</h5>
                <p>${item.source}</p>
            </div>
        ` : ''}
    `;
    
    document.getElementById('item-modal').classList.remove('hidden');
}

// ===== 事件绑定 =====

function bindEvents() {
    // 登录/注册切换
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const tab = btn.dataset.tab;
            document.getElementById('login-form').classList.toggle('hidden', tab !== 'login');
            document.getElementById('register-form').classList.toggle('hidden', tab !== 'register');
        });
    });
    
    // 登录表单
    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const phone = document.getElementById('login-phone').value.trim();
        const password = document.getElementById('login-password').value;
        
        if (!phone || !password) {
            showToast('请填写完整信息', 'error');
            return;
        }
        
        try {
            const result = await apiRequest('/auth/login', {
                method: 'POST',
                body: { phone, password },
            });
            setAuth(result.access_token, result.user);
            showToast('登录成功', 'success');
            showMainPage();
        } catch (error) {
            showToast(error.message, 'error');
        }
    });
    
    // 注册表单
    document.getElementById('register-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const phone = document.getElementById('register-phone').value.trim();
        const password = document.getElementById('register-password').value;
        const nickname = document.getElementById('register-nickname').value.trim() || '梦友';
        
        if (!phone || !password) {
            showToast('请填写完整信息', 'error');
            return;
        }
        
        if (!/^1[3-9]\d{9}$/.test(phone)) {
            showToast('请输入正确的手机号', 'error');
            return;
        }
        
        if (password.length < 6) {
            showToast('密码至少 6 位', 'error');
            return;
        }
        
        try {
            const result = await apiRequest('/auth/register', {
                method: 'POST',
                body: { phone, password, nickname },
            });
            setAuth(result.access_token, result.user);
            showToast('注册成功', 'success');
            showMainPage();
        } catch (error) {
            showToast(error.message, 'error');
        }
    });
    
    // 退出登录
    document.getElementById('logout-btn').addEventListener('click', logout);
    
    // 底部导航
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => showSection(item.dataset.section));
    });
    
    // 新梦按钮
    document.getElementById('new-dream-btn').addEventListener('click', () => {
        showSection('record-section');
        document.getElementById('dream-date').value = new Date().toISOString().split('T')[0];
    });
    
    // 返回按钮
    document.getElementById('back-to-list').addEventListener('click', () => showSection('dreams-section'));
    document.getElementById('back-to-list-2').addEventListener('click', () => showSection('dreams-section'));
    
    // 标签选择
    document.querySelectorAll('#emotion-tags .tag, #scene-tags .tag').forEach(tag => {
        tag.addEventListener('click', () => tag.classList.toggle('selected'));
    });
    
    // 梦境表单
    document.getElementById('dream-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const content = document.getElementById('dream-content').value.trim();
        const dreamDate = document.getElementById('dream-date').value;
        
        if (content.length < 5) {
            showToast('梦境描述至少 5 个字', 'error');
            return;
        }
        
        const emotionTags = [...document.querySelectorAll('#emotion-tags .tag.selected')].map(t => t.dataset.value);
        const sceneTags = [...document.querySelectorAll('#scene-tags .tag.selected')].map(t => t.dataset.value);
        
        await saveDream({
            content,
            dream_date: dreamDate,
            emotion_tags: emotionTags.length ? emotionTags : null,
            scene_tags: sceneTags.length ? sceneTags : null,
        });
    });
    
    // 重新生成
    document.getElementById('regenerate-btn').addEventListener('click', regenerateInterpretation);
    
    // 百科搜索
    document.getElementById('encyclopedia-search').addEventListener('input', filterEncyclopedia);
    
    // 百科分类
    document.querySelectorAll('.category-tag').forEach(tag => {
        tag.addEventListener('click', () => {
            document.querySelectorAll('.category-tag').forEach(t => t.classList.remove('active'));
            tag.classList.add('active');
            filterEncyclopedia();
        });
    });
    
    // 弹窗关闭
    document.getElementById('modal-close').addEventListener('click', () => {
        document.getElementById('item-modal').classList.add('hidden');
    });
    document.getElementById('item-modal').addEventListener('click', (e) => {
        if (e.target.id === 'item-modal') {
            document.getElementById('item-modal').classList.add('hidden');
        }
    });
}

// ===== 初始化 =====

document.addEventListener('DOMContentLoaded', () => {
    bindEvents();
    
    // 检查是否已登录
    if (currentToken && currentUser) {
        showMainPage();
    } else {
        showAuthPage();
    }
});
