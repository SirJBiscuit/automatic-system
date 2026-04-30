/**
 * Filebrowser Social Plugin
 * Adds friends, chat, file sharing, and online status directly to filebrowser
 */

(function() {
    'use strict';
    
    console.log('🚀 Filebrowser Social Plugin Loading...');
    
    // Configuration
    const CONFIG = {
        apiBase: window.location.origin,
        statusCheckInterval: 30000, // 30 seconds
        heartbeatInterval: 60000, // 1 minute
        storageKey: 'filebrowser_social'
    };
    
    // State
    let currentUser = null;
    let friends = [];
    let onlineUsers = new Set();
    let chatMessages = [];
    
    // Initialize when page loads
    window.addEventListener('load', function() {
        setTimeout(initSocialFeatures, 1000); // Wait for filebrowser to load
    });
    
    function initSocialFeatures() {
        console.log('Initializing social features...');
        
        // Get current user from filebrowser
        getCurrentUser();
        
        // Create UI elements
        createFriendsSidebar();
        createChatPanel();
        createContextMenuEnhancements();
        
        // Start background tasks
        startHeartbeat();
        startStatusCheck();
        
        console.log('✅ Social features loaded!');
    }
    
    function getCurrentUser() {
        // Try to get username from filebrowser's UI
        const userElement = document.querySelector('[data-username]') || 
                          document.querySelector('.user-name') ||
                          document.querySelector('.username');
        
        if (userElement) {
            currentUser = userElement.textContent.trim() || userElement.dataset.username;
        } else {
            // Fallback: check localStorage or session
            currentUser = localStorage.getItem('filebrowser_username') || 'user';
        }
        
        console.log('Current user:', currentUser);
        return currentUser;
    }
    
    function createFriendsSidebar() {
        // Create sidebar container
        const sidebar = document.createElement('div');
        sidebar.id = 'social-sidebar';
        sidebar.innerHTML = `
            <div class="social-sidebar-header">
                <h3>👥 Friends</h3>
                <button class="add-friend-btn" onclick="window.socialPlugin.showAddFriend()">➕</button>
            </div>
            <div class="friends-list" id="friendsList">
                <div class="loading">Loading friends...</div>
            </div>
            <div class="social-actions">
                <button onclick="window.socialPlugin.toggleChat()">💬 Chat</button>
                <button onclick="window.socialPlugin.showSettings()">⚙️</button>
            </div>
        `;
        
        document.body.appendChild(sidebar);
        
        // Load friends
        loadFriends();
    }
    
    function createChatPanel() {
        const chatPanel = document.createElement('div');
        chatPanel.id = 'chat-panel';
        chatPanel.className = 'chat-panel hidden';
        chatPanel.innerHTML = `
            <div class="chat-header">
                <h3>💬 Chat</h3>
                <button onclick="window.socialPlugin.toggleChat()">✕</button>
            </div>
            <div class="chat-messages" id="chatMessages"></div>
            <div class="chat-input-container">
                <input type="text" id="chatInput" placeholder="Type a message...">
                <button onclick="window.socialPlugin.sendMessage()">Send</button>
            </div>
        `;
        
        document.body.appendChild(chatPanel);
        
        // Enter to send
        document.getElementById('chatInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                window.socialPlugin.sendMessage();
            }
        });
    }
    
    function createContextMenuEnhancements() {
        // Add right-click menu to files for sharing
        document.addEventListener('contextmenu', function(e) {
            const fileItem = e.target.closest('[data-type="file"], [data-type="dir"]');
            if (fileItem) {
                e.preventDefault();
                showFileContextMenu(e.pageX, e.pageY, fileItem);
            }
        });
    }
    
    function showFileContextMenu(x, y, fileItem) {
        // Remove existing menu
        const existing = document.getElementById('social-context-menu');
        if (existing) existing.remove();
        
        const menu = document.createElement('div');
        menu.id = 'social-context-menu';
        menu.style.left = x + 'px';
        menu.style.top = y + 'px';
        
        const fileName = fileItem.dataset.name || fileItem.textContent.trim();
        
        menu.innerHTML = `
            <div class="context-item" onclick="window.socialPlugin.shareWithFriend('${fileName}')">
                📤 Send to Friend
            </div>
            <div class="context-item" onclick="window.socialPlugin.startTrade('${fileName}')">
                🔄 Start Trade
            </div>
            <div class="context-divider"></div>
            <div class="context-item" onclick="window.socialPlugin.createShareLink('${fileName}')">
                🔗 Create Share Link
            </div>
        `;
        
        document.body.appendChild(menu);
        
        // Close on click outside
        setTimeout(() => {
            document.addEventListener('click', function closeMenu() {
                menu.remove();
                document.removeEventListener('click', closeMenu);
            });
        }, 100);
    }
    
    function loadFriends() {
        // Load from localStorage for now (will be API later)
        const stored = localStorage.getItem(CONFIG.storageKey + '_friends');
        friends = stored ? JSON.parse(stored) : [];
        
        renderFriends();
    }
    
    function renderFriends() {
        const list = document.getElementById('friendsList');
        if (!list) return;
        
        if (friends.length === 0) {
            list.innerHTML = '<div class="no-friends">No friends yet. Click ➕ to add!</div>';
            return;
        }
        
        list.innerHTML = friends.map(friend => `
            <div class="friend-item" data-username="${friend.username}">
                <div class="friend-avatar">${friend.username.charAt(0).toUpperCase()}</div>
                <div class="friend-info">
                    <div class="friend-name">${friend.username}</div>
                    <div class="friend-status ${onlineUsers.has(friend.username) ? 'online' : 'offline'}">
                        ${onlineUsers.has(friend.username) ? '🟢 Online' : '⚫ Offline'}
                    </div>
                </div>
                <div class="friend-actions">
                    <button onclick="window.socialPlugin.sendFileTo('${friend.username}')" title="Send File">📤</button>
                    <button onclick="window.socialPlugin.chatWith('${friend.username}')" title="Chat">💬</button>
                </div>
            </div>
        `).join('');
    }
    
    function startHeartbeat() {
        // Send heartbeat to mark user as online
        setInterval(() => {
            const timestamp = Date.now();
            localStorage.setItem(CONFIG.storageKey + '_heartbeat_' + currentUser, timestamp);
            
            // Also update in shared storage if available
            if (typeof SharedWorker !== 'undefined') {
                // Use SharedWorker for cross-tab communication
                updateSharedHeartbeat(timestamp);
            }
        }, CONFIG.heartbeatInterval);
    }
    
    function startStatusCheck() {
        // Check friends' online status
        setInterval(() => {
            checkFriendsStatus();
        }, CONFIG.statusCheckInterval);
        
        // Initial check
        checkFriendsStatus();
    }
    
    function checkFriendsStatus() {
        const now = Date.now();
        const onlineThreshold = 5 * 60 * 1000; // 5 minutes
        
        onlineUsers.clear();
        
        friends.forEach(friend => {
            const heartbeat = localStorage.getItem(CONFIG.storageKey + '_heartbeat_' + friend.username);
            if (heartbeat && (now - parseInt(heartbeat)) < onlineThreshold) {
                onlineUsers.add(friend.username);
            }
        });
        
        renderFriends();
    }
    
    function updateSharedHeartbeat(timestamp) {
        // Placeholder for SharedWorker implementation
        // This would allow cross-tab real-time updates
    }
    
    // Public API
    window.socialPlugin = {
        showAddFriend: function() {
            const username = prompt('Enter friend\'s username:');
            if (username && username.trim()) {
                addFriend(username.trim());
            }
        },
        
        toggleChat: function() {
            const panel = document.getElementById('chat-panel');
            panel.classList.toggle('hidden');
        },
        
        sendMessage: function() {
            const input = document.getElementById('chatInput');
            const message = input.value.trim();
            
            if (message) {
                const msg = {
                    from: currentUser,
                    text: message,
                    timestamp: Date.now()
                };
                
                chatMessages.push(msg);
                saveChatMessages();
                renderChatMessages();
                input.value = '';
            }
        },
        
        shareWithFriend: function(fileName) {
            const friend = prompt('Send "' + fileName + '" to which friend?');
            if (friend) {
                sendFileToFriend(fileName, friend);
            }
        },
        
        startTrade: function(fileName) {
            alert('Trade feature: Select files to trade with ' + fileName);
            // Will implement drag-drop trade UI
        },
        
        createShareLink: function(fileName) {
            // Use filebrowser's built-in share functionality
            alert('Creating share link for: ' + fileName);
        },
        
        sendFileTo: function(username) {
            alert('Select a file to send to ' + username);
            // Will implement file picker
        },
        
        chatWith: function(username) {
            this.toggleChat();
            // Load chat history with this user
        },
        
        showSettings: function() {
            alert('Settings panel coming soon!');
        }
    };
    
    function addFriend(username) {
        if (friends.some(f => f.username === username)) {
            alert('Already friends with ' + username);
            return;
        }
        
        friends.push({ username, addedAt: Date.now() });
        saveFriends();
        renderFriends();
        
        showNotification('Added ' + username + ' as a friend!');
    }
    
    function saveFriends() {
        localStorage.setItem(CONFIG.storageKey + '_friends', JSON.stringify(friends));
    }
    
    function saveChatMessages() {
        localStorage.setItem(CONFIG.storageKey + '_chat', JSON.stringify(chatMessages));
    }
    
    function renderChatMessages() {
        const container = document.getElementById('chatMessages');
        if (!container) return;
        
        container.innerHTML = chatMessages.map(msg => `
            <div class="chat-message ${msg.from === currentUser ? 'own' : 'other'}">
                <div class="message-sender">${msg.from}</div>
                <div class="message-text">${escapeHtml(msg.text)}</div>
                <div class="message-time">${new Date(msg.timestamp).toLocaleTimeString()}</div>
            </div>
        `).join('');
        
        container.scrollTop = container.scrollHeight;
    }
    
    function sendFileToFriend(fileName, friendUsername) {
        showNotification('Sending ' + fileName + ' to ' + friendUsername + '...');
        
        // Store in pending transfers
        const transfers = JSON.parse(localStorage.getItem(CONFIG.storageKey + '_transfers') || '[]');
        transfers.push({
            from: currentUser,
            to: friendUsername,
            file: fileName,
            timestamp: Date.now(),
            status: 'pending'
        });
        localStorage.setItem(CONFIG.storageKey + '_transfers', JSON.stringify(transfers));
        
        showNotification('File sent! Waiting for ' + friendUsername + ' to accept.');
    }
    
    function showNotification(message) {
        const notif = document.createElement('div');
        notif.className = 'social-notification';
        notif.textContent = message;
        document.body.appendChild(notif);
        
        setTimeout(() => notif.classList.add('show'), 100);
        setTimeout(() => {
            notif.classList.remove('show');
            setTimeout(() => notif.remove(), 300);
        }, 3000);
    }
    
    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
    
    console.log('✅ Filebrowser Social Plugin Loaded');
})();
