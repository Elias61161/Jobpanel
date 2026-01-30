// State
var currentJob = null;
var employees = [];
var grades = {};
var permissions = [];
var societyMoney = 0;
var playerMoney = { cash: 0, bank: 0 };
var salaryHistory = [];
var transactions = [];
var statistics = {};
var auditLog = [];
var jobConfig = {};
var selectedGrade = null;
var depositType = 'cash';
var withdrawType = 'cash';

// Message listener
window.addEventListener('message', function(event) {
    var data = event.data;
    
    if (data.action === 'open') {
        openPanel(data);
    } else if (data.action === 'close') {
        hidePanel();
    } else if (data.action === 'refresh') {
        refreshData(data);
    } else if (data.action === 'updateJob') {
        currentJob = data.job;
        updateHeader();
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closePanel();
    }
});

function openPanel(data) {
    currentJob = data.job;
    employees = data.employees || [];
    grades = data.grades || {};
    permissions = data.permissions || [];
    societyMoney = data.societyMoney || 0;
    playerMoney = data.playerMoney || { cash: 0, bank: 0 };
    salaryHistory = data.salaryHistory || [];
    transactions = data.transactions || [];
    statistics = data.statistics || {};
    auditLog = data.auditLog || [];
    jobConfig = data.jobConfig || {};
    
    updateHeader();
    updateAllStats();
    updatePermissionVisibility();
    renderEmployees();
    renderPayroll();
    renderGrades();
    renderTransactions();
    renderActivity();
    renderOnlineStaff();
    renderStatistics();
    renderAudit();
    updatePlayerMoney();
    
    document.getElementById('panel').classList.add('active');
}

function hidePanel() {
    document.getElementById('panel').classList.remove('active');
}

function closePanel() {
    hidePanel();
    post('close', {});
}

function refreshData(data) {
    employees = data.employees || employees;
    grades = data.grades || grades;
    societyMoney = data.societyMoney || societyMoney;
    playerMoney = data.playerMoney || playerMoney;
    salaryHistory = data.salaryHistory || salaryHistory;
    transactions = data.transactions || transactions;
    statistics = data.statistics || statistics;
    auditLog = data.auditLog || auditLog;
    
    updateAllStats();
    renderEmployees();
    renderPayroll();
    renderGrades();
    renderTransactions();
    renderActivity();
    renderOnlineStaff();
    renderStatistics();
    renderAudit();
    updatePlayerMoney();
}

function updateHeader() {
    document.getElementById('companyName').textContent = currentJob.label;
    document.getElementById('userRank').textContent = currentJob.grade_label;
    
    var logo = document.getElementById('companyLogo');
    if (jobConfig.logo) {
        logo.src = jobConfig.logo;
        logo.style.display = 'block';
    } else {
        logo.style.display = 'none';
    }
}

function updateAllStats() {
    var total = employees.length;
    var online = employees.filter(function(e) { return e.isOnline; }).length;
    var salaries = employees.filter(function(e) { return e.isOnline; }).reduce(function(s, e) { return s + e.salary; }, 0);
    
    document.getElementById('statEmployees').textContent = total;
    document.getElementById('statOnline').textContent = online;
    document.getElementById('statSalary').textContent = formatMoney(salaries);
    document.getElementById('statVault').textContent = formatMoney(societyMoney);
    document.getElementById('sidebarBalance').textContent = formatMoney(societyMoney);
    document.getElementById('financeBalance').textContent = formatMoney(societyMoney);
    document.getElementById('employeeCount').textContent = total;
    
    document.getElementById('payrollOnline').textContent = online;
    document.getElementById('payrollCost').textContent = formatMoney(salaries);
    document.getElementById('payrollAvailable').textContent = formatMoney(societyMoney);
}

function updatePermissionVisibility() {
    document.querySelectorAll('[data-perm]').forEach(function(el) {
        var perm = el.getAttribute('data-perm');
        if (hasPerm(perm)) {
            el.classList.remove('hidden');
        } else {
            el.classList.add('hidden');
        }
    });
    
    var withdrawCard = document.getElementById('withdrawCard');
    if (withdrawCard) {
        if (hasPerm('manage_finances')) {
            withdrawCard.classList.remove('disabled');
        } else {
            withdrawCard.classList.add('disabled');
        }
    }
}

function hasPerm(perm) {
    return permissions.indexOf(perm) !== -1;
}

function updatePlayerMoney() {
    document.getElementById('depositCash').textContent = formatMoney(playerMoney.cash);
    document.getElementById('depositBank').textContent = formatMoney(playerMoney.bank);
}

// Navigation
document.querySelectorAll('.nav-item').forEach(function(btn) {
    btn.addEventListener('click', function() {
        if (this.classList.contains('hidden')) return;
        switchTab(this.getAttribute('data-tab'));
    });
});

function switchTab(tabName) {
    document.querySelectorAll('.nav-item').forEach(function(b) { b.classList.remove('active'); });
    document.querySelectorAll('.tab-section').forEach(function(s) { s.classList.remove('active'); });
    
    var btn = document.querySelector('.nav-item[data-tab="' + tabName + '"]');
    if (btn) btn.classList.add('active');
    
    var section = document.getElementById(tabName);
    if (section) section.classList.add('active');
}

// Render Employees
function renderEmployees() {
    var container = document.getElementById('employeeGrid');
    var search = document.getElementById('employeeSearch');
    var filter = document.getElementById('employeeFilter');
    var term = search ? search.value.toLowerCase() : '';
    var filterVal = filter ? filter.value : 'all';
    
    var filtered = employees.filter(function(e) {
        var matchSearch = e.name.toLowerCase().indexOf(term) !== -1 || e.gradeLabel.toLowerCase().indexOf(term) !== -1;
        var matchFilter = filterVal === 'all' || (filterVal === 'online' && e.isOnline) || (filterVal === 'offline' && !e.isOnline);
        return matchSearch && matchFilter;
    });
    
    if (filtered.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-users-slash"></i><p>Inga anställda hittades</p></div>';
        return;
    }
    
    var html = '';
    for (var i = 0; i < filtered.length; i++) {
        var e = filtered[i];
        html += '<div class="employee-card ' + (e.isOnline ? 'online' : '') + '">' +
            '<div class="employee-header">' +
                '<div class="employee-avatar ' + (e.isOnline ? 'online' : '') + '">' + getInitials(e.name) + '</div>' +
                '<div class="employee-details">' +
                    '<h4>' + esc(e.name) + '</h4>' +
                    '<span class="rank"><i class="fas fa-star"></i> ' + esc(e.gradeLabel) + '</span>' +
                '</div>' +
            '</div>' +
            '<div class="employee-stats">' +
                '<div class="emp-stat">' +
                    '<span class="emp-stat-value">' + formatMoney(e.salary) + '</span>' +
                    '<span class="emp-stat-label">Lön</span>' +
                '</div>' +
                '<div class="emp-stat">' +
                    '<span class="emp-stat-value">' + formatMoney(e.bonus || 0) + '</span>' +
                    '<span class="emp-stat-label">Bonus</span>' +
                '</div>' +
            '</div>';
        
        // Notes
        if (e.notes && e.notes.length > 0 && hasPerm('manage_notes')) {
            html += '<div class="employee-notes">' +
                '<div class="notes-title"><i class="fas fa-sticky-note"></i> Anteckningar</div>';
            for (var n = 0; n < Math.min(e.notes.length, 2); n++) {
                html += '<div class="note-item">' +
                    '<p>' + esc(e.notes[n].note) + '</p>' +
                    '<small>- ' + esc(e.notes[n].created_by_name) + '</small>' +
                '</div>';
            }
            html += '</div>';
        }
        
        html += '<div class="employee-actions">';
        if (hasPerm('manage_grades')) {
            html += '<button class="btn btn-secondary btn-sm" onclick="openGradeModal(\'' + e.identifier + '\', \'' + esc(e.name) + '\', ' + e.grade + ')"><i class="fas fa-edit"></i></button>';
        }
        if (hasPerm('manage_notes')) {
            html += '<button class="btn btn-secondary btn-sm" onclick="openNoteModal(\'' + e.identifier + '\', \'' + esc(e.name) + '\')"><i class="fas fa-sticky-note"></i></button>';
        }
        if (hasPerm('hire_fire')) {
            html += '<button class="btn btn-danger btn-sm" onclick="openFireModal(\'' + e.identifier + '\', \'' + esc(e.name) + '\')"><i class="fas fa-user-minus"></i></button>';
        }
        html += '</div></div>';
    }
    
    container.innerHTML = html;
}

document.getElementById('employeeSearch').addEventListener('input', renderEmployees);
document.getElementById('employeeFilter').addEventListener('change', renderEmployees);

// Render Payroll
function renderPayroll() {
    var container = document.getElementById('payrollList');
    var online = employees.filter(function(e) { return e.isOnline; });
    
    if (online.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-user-clock"></i><p>Inga anställda online</p></div>';
        return;
    }
    
    var html = '';
    for (var i = 0; i < online.length; i++) {
        var e = online[i];
        html += '<div class="payroll-card">' +
            '<div class="payroll-left">' +
                '<div class="payroll-avatar">' + getInitials(e.name) + '</div>' +
                '<div class="payroll-info">' +
                    '<h4>' + esc(e.name) + '</h4>' +
                    '<span>' + esc(e.gradeLabel) + '</span>' +
                '</div>' +
            '</div>' +
            '<div class="payroll-right">' +
                '<div class="payroll-amount">' +
                    '<span class="amount">' + formatMoney(e.salary) + '</span>' +
                    (e.bonus > 0 ? '<span class="bonus">+' + formatMoney(e.bonus) + '</span>' : '') +
                '</div>' +
                '<div class="payroll-actions">' +
                    '<button class="btn btn-success btn-sm" onclick="paySalary(\'' + e.identifier + '\', ' + e.salary + ')"><i class="fas fa-money-bill"></i></button>' +
                    '<button class="btn btn-primary btn-sm" onclick="openBonusModal(\'' + e.identifier + '\', \'' + esc(e.name) + '\')"><i class="fas fa-gift"></i></button>' +
                '</div>' +
            '</div>' +
        '</div>';
    }
    
    container.innerHTML = html;
}

// Render Grades
function renderGrades() {
    var container = document.getElementById('gradesList');
    var gradeKeys = Object.keys(grades).sort(function(a, b) { return parseInt(b) - parseInt(a); });
    
    var html = '';
    for (var i = 0; i < gradeKeys.length; i++) {
        var g = gradeKeys[i];
        var info = grades[g];
        
        html += '<div class="grade-card" id="grade-' + g + '">' +
            '<div class="grade-left">' +
                '<div class="grade-number">' + g + '</div>' +
                '<div class="grade-info">' +
                    '<h4>' + esc(info.name) + '</h4>' +
                    '<span>Rank ' + g + '</span>' +
                '</div>' +
            '</div>' +
            '<div class="grade-right">';
        
        if (hasPerm('manage_salary')) {
            html += '<div class="grade-input-group">' +
                    '<label>Lön</label>' +
                    '<input type="number" class="salary" id="salary-' + g + '" value="' + info.salary + '" onchange="markEditing(' + g + ')">' +
                '</div>' +
                '<div class="grade-input-group">' +
                    '<label>Bonus</label>' +
                    '<input type="number" class="bonus" id="bonus-' + g + '" value="' + (info.bonus || 0) + '" onchange="markEditing(' + g + ')">' +
                '</div>' +
                '<button class="btn btn-success btn-sm" onclick="saveSalary(' + g + ')"><i class="fas fa-save"></i></button>';
        } else {
            html += '<div class="grade-input-group">' +
                    '<label>Lön</label>' +
                    '<span style="font-size:18px;font-weight:700;color:var(--success)">' + formatMoney(info.salary) + '</span>' +
                '</div>';
        }
        
        html += '</div></div>';
    }
    
    container.innerHTML = html;
}

function markEditing(grade) {
    var el = document.getElementById('grade-' + grade);
    if (el) el.classList.add('editing');
}

function saveSalary(grade) {
    var salary = parseInt(document.getElementById('salary-' + grade).value) || 0;
    var bonus = parseInt(document.getElementById('bonus-' + grade).value) || 0;
    
    post('updateSalary', { grade: grade, salary: salary, bonus: bonus });
    
    var el = document.getElementById('grade-' + grade);
    if (el) el.classList.remove('editing');
}

// Render Transactions
function renderTransactions() {
    var container = document.getElementById('transactionList');
    
    if (!transactions || transactions.length === 0) {
        container.innerHTML = '<div class="empty-state small"><i class="fas fa-receipt"></i><p>Inga transaktioner</p></div>';
        return;
    }
    
    var html = '';
    var items = transactions.slice(0, 20);
    
    for (var i = 0; i < items.length; i++) {
        var t = items[i];
        var isPos = t.type === 'deposit';
        var icon = t.type === 'deposit' ? 'arrow-down' : t.type === 'withdraw' ? 'arrow-up' : 'money-bill';
        var iconClass = t.type === 'deposit' ? 'deposit' : t.type === 'withdraw' ? 'withdraw' : 'salary';
        var label = t.type === 'deposit' ? 'Insättning' : t.type === 'withdraw' ? 'Uttag' : 'Löneutbetalning';
        
        html += '<div class="transaction-item">' +
            '<div class="transaction-left">' +
                '<div class="transaction-icon ' + iconClass + '"><i class="fas fa-' + icon + '"></i></div>' +
                '<div class="transaction-details">' +
                    '<p>' + label + '</p>' +
                    '<small>' + esc(t.name) + '</small>' +
                '</div>' +
            '</div>' +
            '<div class="transaction-right">' +
                '<span class="transaction-amount ' + (isPos ? 'positive' : 'negative') + '">' + (isPos ? '+' : '-') + formatMoney(t.amount) + '</span>' +
                '<span class="transaction-date">' + formatDate(t.created_at) + '</span>' +
            '</div>' +
        '</div>';
    }
    
    container.innerHTML = html;
}

// Render Activity
function renderActivity() {
    var container = document.getElementById('recentActivity');
    
    if (!salaryHistory || salaryHistory.length === 0) {
        container.innerHTML = '<div class="empty-state small"><i class="fas fa-inbox"></i><p>Ingen aktivitet</p></div>';
        return;
    }
    
    var html = '';
    var items = salaryHistory.slice(0, 6);
    
    for (var i = 0; i < items.length; i++) {
        var item = items[i];
        var icon = item.payment_type === 'bonus' ? 'gift' : 'money-bill';
        var iconClass = item.payment_type === 'bonus' ? 'bonus' : 'salary';
        
        html += '<div class="activity-item">' +
            '<div class="activity-icon ' + iconClass + '"><i class="fas fa-' + icon + '"></i></div>' +
            '<div class="activity-content">' +
                '<p>' + formatMoney(item.amount) + ' → ' + esc(item.employee_name) + '</p>' +
                '<span>' + formatDate(item.created_at) + '</span>' +
            '</div>' +
        '</div>';
    }
    
    container.innerHTML = html;
}

// Render Online Staff
function renderOnlineStaff() {
    var container = document.getElementById('onlineStaff');
    var online = employees.filter(function(e) { return e.isOnline; });
    
    if (online.length === 0) {
        container.innerHTML = '<div class="empty-state small"><i class="fas fa-users-slash"></i><p>Ingen online</p></div>';
        return;
    }
    
    var html = '';
    for (var i = 0; i < Math.min(online.length, 6); i++) {
        var e = online[i];
        html += '<div class="staff-item">' +
            '<div class="staff-avatar">' + getInitials(e.name) + '</div>' +
            '<div class="staff-info">' +
                '<h4>' + esc(e.name) + '</h4>' +
                '<span>' + esc(e.gradeLabel) + '</span>' +
            '</div>' +
        '</div>';
    }
    
    container.innerHTML = html;
}

// Render Statistics
function renderStatistics() {
    document.getElementById('statTotalPaid').textContent = formatMoney(statistics.totalPaid || 0);
    document.getElementById('statWeekly').textContent = statistics.paymentsThisWeek || 0;
    document.getElementById('statDeposited').textContent = formatMoney(statistics.totalDeposited || 0);
    document.getElementById('statWithdrawn').textContent = formatMoney(statistics.totalWithdrawn || 0);
}

// Render Audit
function renderAudit() {
    var container = document.getElementById('auditList');
    
    if (!auditLog || auditLog.length === 0) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-clipboard-list"></i><p>Ingen logg</p></div>';
        return;
    }
    
    var actionLabels = {
        'PAY_SALARY': 'Löneutbetalning',
        'PAY_BONUS': 'Bonusutbetalning',
        'PAY_ALL': 'Massutbetalning',
        'HIRE': 'Anställning',
        'FIRE': 'Avsked',
        'SET_GRADE': 'Rankändring',
        'UPDATE_SALARY': 'Löneändring',
        'DEPOSIT': 'Insättning',
        'WITHDRAW': 'Uttag'
    };
    
    var html = '';
    for (var i = 0; i < Math.min(auditLog.length, 30); i++) {
        var log = auditLog[i];
        var label = actionLabels[log.action] || log.action;
        
        html += '<div class="audit-item">' +
            '<div class="audit-icon"><i class="fas fa-clipboard-check"></i></div>' +
            '<div class="audit-content">' +
                '<h4>' + label + '</h4>' +
                '<p>Av: ' + esc(log.performed_by) + '</p>' +
            '</div>' +
            '<span class="audit-date">' + formatDate(log.created_at) + '</span>' +
        '</div>';
    }
    
    container.innerHTML = html;
}

// Money Selection
function selectMoney(el, action) {
    var parent = el.parentElement;
    parent.querySelectorAll('.money-btn').forEach(function(b) { b.classList.remove('active'); });
    el.classList.add('active');
    
    var type = el.getAttribute('data-type');
    if (action === 'deposit') {
        depositType = type;
    } else {
        withdrawType = type;
    }
}

// Finance Actions
function doDeposit() {
    var amount = parseInt(document.getElementById('depositAmount').value) || 0;
    if (amount <= 0) return;
    post('depositMoney', { amount: amount, moneyType: depositType, note: '' });
    document.getElementById('depositAmount').value = '';
}

function doWithdraw() {
    var amount = parseInt(document.getElementById('withdrawAmount').value) || 0;
    if (amount <= 0) return;
    post('withdrawMoney', { amount: amount, moneyType: withdrawType, note: '' });
    document.getElementById('withdrawAmount').value = '';
}

// Search Nearby
function searchNearby() {
    var container = document.getElementById('nearbyGrid');
    container.innerHTML = '<div class="empty-state small"><div class="spinner"></div><p>Söker...</p></div>';
    
    fetch('https://jobpanel/getNearbyPlayers', {
        method: 'POST',
        body: JSON.stringify({})
    })
    .then(function(r) { return r.json(); })
    .then(function(players) {
        if (players.length === 0) {
            container.innerHTML = '<div class="empty-state"><i class="fas fa-map-marker-alt"></i><p>Inga spelare i närheten</p></div>';
            return;
        }
        
        var html = '';
        for (var i = 0; i < players.length; i++) {
            var p = players[i];
            html += '<div class="nearby-card">' +
                '<div class="nearby-info">' +
                    '<div class="nearby-avatar"><i class="fas fa-user"></i></div>' +
                    '<div class="nearby-details">' +
                        '<h4>' + esc(p.name) + '</h4>' +
                        '<span>ID: ' + p.id + ' • ' + esc(p.job) + '</span>' +
                    '</div>' +
                '</div>' +
                '<button class="btn btn-success" onclick="openHireModal(' + p.id + ', \'' + esc(p.name) + '\')"><i class="fas fa-user-plus"></i> Anställ</button>' +
            '</div>';
        }
        container.innerHTML = html;
    });
}

// Modals
function openHireModal(playerId, playerName) {
    document.getElementById('modalTitle').textContent = 'Anställ ' + playerName;
    
    var gradeKeys = Object.keys(grades).filter(function(g) { return parseInt(g) < currentJob.grade; }).sort(function(a, b) { return parseInt(a) - parseInt(b); });
    
    if (gradeKeys.length === 0) {
        document.getElementById('modalBody').innerHTML = '<div class="alert-box info"><i class="fas fa-info-circle"></i><p>Du kan inte anställa med din rank.</p></div><div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Stäng</button></div>';
    } else {
        var html = '<p style="color:var(--text-muted);margin-bottom:18px;">Välj rank för den nya anställda:</p><div class="grade-selector">';
        for (var i = 0; i < gradeKeys.length; i++) {
            var g = gradeKeys[i];
            var info = grades[g];
            html += '<div class="grade-option" onclick="selectGradeOpt(this,' + g + ')">' +
                '<div class="grade-option-left">' +
                    '<div class="grade-option-num">' + g + '</div>' +
                    '<span class="grade-option-name">' + esc(info.name) + '</span>' +
                '</div>' +
                '<span class="grade-option-salary">' + formatMoney(info.salary) + '</span>' +
            '</div>';
        }
        html += '</div><div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Avbryt</button><button class="btn btn-success" id="confirmHireBtn" onclick="confirmHire(' + playerId + ')" disabled><i class="fas fa-user-plus"></i> Anställ</button></div>';
        document.getElementById('modalBody').innerHTML = html;
    }
    
    selectedGrade = null;
    document.getElementById('modal').classList.add('active');
}

function selectGradeOpt(el, grade) {
    document.querySelectorAll('.grade-option').forEach(function(o) { o.classList.remove('selected'); });
    el.classList.add('selected');
    selectedGrade = grade;
    var btn = document.getElementById('confirmHireBtn');
    if (btn) btn.disabled = false;
}

function confirmHire(playerId) {
    if (selectedGrade === null) return;
    post('hireEmployee', { playerId: playerId, grade: selectedGrade });
    closeModal();
}

function openGradeModal(identifier, name, currentGradeVal) {
    document.getElementById('modalTitle').textContent = 'Ändra rank - ' + name;
    
    var gradeKeys = Object.keys(grades).filter(function(g) { return parseInt(g) < currentJob.grade; }).sort(function(a, b) { return parseInt(a) - parseInt(b); });
    var currentName = grades[currentGradeVal] ? grades[currentGradeVal].name : 'Okänd';
    
    var html = '<p style="color:var(--text-muted);margin-bottom:18px;">Nuvarande rank: <strong>' + esc(currentName) + '</strong></p><div class="grade-selector">';
    for (var i = 0; i < gradeKeys.length; i++) {
        var g = gradeKeys[i];
        var info = grades[g];
        var sel = parseInt(g) === currentGradeVal ? 'selected' : '';
        html += '<div class="grade-option ' + sel + '" onclick="selectGradeOpt(this,' + g + ')">' +
            '<div class="grade-option-left">' +
                '<div class="grade-option-num">' + g + '</div>' +
                '<span class="grade-option-name">' + esc(info.name) + '</span>' +
            '</div>' +
            '<span class="grade-option-salary">' + formatMoney(info.salary) + '</span>' +
        '</div>';
    }
    html += '</div><div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Avbryt</button><button class="btn btn-primary" onclick="confirmGrade(\'' + identifier + '\')"><i class="fas fa-save"></i> Spara</button></div>';
    
    document.getElementById('modalBody').innerHTML = html;
    selectedGrade = currentGradeVal;
    document.getElementById('modal').classList.add('active');
}

function confirmGrade(identifier) {
    if (selectedGrade === null) return;
    post('setGrade', { identifier: identifier, grade: selectedGrade });
    closeModal();
}

function openFireModal(identifier, name) {
    document.getElementById('modalTitle').textContent = 'Avskeda Anställd';
    document.getElementById('modalBody').innerHTML = '<div class="alert-box warning"><i class="fas fa-exclamation-triangle"></i><p>Är du säker på att du vill avskeda <strong>' + esc(name) + '</strong>? Detta går inte att ångra.</p></div><div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Avbryt</button><button class="btn btn-danger" onclick="confirmFire(\'' + identifier + '\')"><i class="fas fa-user-minus"></i> Avskeda</button></div>';
    document.getElementById('modal').classList.add('active');
}

function confirmFire(identifier) {
    post('fireEmployee', { identifier: identifier });
    closeModal();
}

function openBonusModal(identifier, name) {
    document.getElementById('modalTitle').textContent = 'Betala Bonus - ' + name;
    document.getElementById('modalBody').innerHTML = '<div class="form-group"><label>Belopp</label><input type="number" id="bonusAmount" placeholder="0"></div><div class="form-group"><label>Anteckning (valfritt)</label><input type="text" id="bonusNote" placeholder="T.ex. Bra jobbat!"></div><div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Avbryt</button><button class="btn btn-success" onclick="confirmBonus(\'' + identifier + '\')"><i class="fas fa-gift"></i> Betala Bonus</button></div>';
    document.getElementById('modal').classList.add('active');
}

function confirmBonus(identifier) {
    var amount = parseInt(document.getElementById('bonusAmount').value) || 0;
    var note = document.getElementById('bonusNote').value;
    if (amount <= 0) return;
    post('payBonus', { identifier: identifier, amount: amount, note: note });
    closeModal();
}

function openNoteModal(identifier, name) {
    document.getElementById('modalTitle').textContent = 'Lägg till Anteckning - ' + name;
    document.getElementById('modalBody').innerHTML = '<div class="form-group"><label>Anteckning</label><textarea id="noteText" rows="4" placeholder="Skriv din anteckning här..."></textarea></div><div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Avbryt</button><button class="btn btn-primary" onclick="confirmNote(\'' + identifier + '\')"><i class="fas fa-save"></i> Spara</button></div>';
    document.getElementById('modal').classList.add('active');
}

function confirmNote(identifier) {
    var note = document.getElementById('noteText').value;
    if (!note || note.trim() === '') return;
    post('addNote', { identifier: identifier, note: note });
    closeModal();
}

function openPayAllModal() {
    document.getElementById('modalTitle').textContent = 'Betala Alla Löner';
    
    var online = employees.filter(function(e) { return e.isOnline; });
    var total = online.reduce(function(s, e) { return s + e.salary; }, 0);
    
    document.getElementById('modalBody').innerHTML = '<div class="alert-box info"><i class="fas fa-info-circle"></i><div><p>Du kommer att betala ut lön till <strong>' + online.length + '</strong> anställda.</p><p style="margin-top:8px;">Total kostnad: <strong style="color:var(--success);">' + formatMoney(total) + '</strong></p></div></div><div class="form-group"><label>Anteckning (valfritt)</label><input type="text" id="payAllNote" placeholder="T.ex. Veckolön"></div><div class="modal-actions"><button class="btn btn-secondary" onclick="closeModal()">Avbryt</button><button class="btn btn-success" onclick="confirmPayAll()"><i class="fas fa-hand-holding-usd"></i> Betala Alla</button></div>';
    document.getElementById('modal').classList.add('active');
}

function confirmPayAll() {
    var note = document.getElementById('payAllNote').value;
    post('payAllSalaries', { note: note });
    closeModal();
}

function closeModal() {
    document.getElementById('modal').classList.remove('active');
    selectedGrade = null;
}

// Direct Actions
function paySalary(identifier, amount) {
    post('paySalary', { identifier: identifier, amount: amount, note: '' });
}

function requestRefresh() {
    post('requestRefresh', {});
}

// Utilities
function post(event, data) {
    fetch('https://jobpanel/' + event, {
        method: 'POST',
        body: JSON.stringify(data || {})
    });
}

function formatMoney(amount) {
    return '$' + (amount || 0).toLocaleString('sv-SE');
}

function formatDate(dateStr) {
    if (!dateStr) return '';
    var d = new Date(dateStr);
    var now = new Date();
    var diff = Math.floor((now - d) / 1000);
    
    if (diff < 60) return 'Just nu';
    if (diff < 3600) return Math.floor(diff / 60) + ' min sedan';
    if (diff < 86400) return Math.floor(diff / 3600) + ' tim sedan';
    if (diff < 604800) return Math.floor(diff / 86400) + ' dagar sedan';
    
    return d.toLocaleDateString('sv-SE') + ' ' + d.toLocaleTimeString('sv-SE', { hour: '2-digit', minute: '2-digit' });
}

function getInitials(name) {
    if (!name) return '??';
    var parts = name.split(' ');
    var initials = '';
    for (var i = 0; i < parts.length && i < 2; i++) {
        initials += parts[i].charAt(0);
    }
    return initials.toUpperCase();
}

function esc(text) {
    if (!text) return '';
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Initialize
console.log('[BossPanel] Premium UI loaded!');