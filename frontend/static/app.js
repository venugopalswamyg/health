const loginScreen = document.getElementById('login-screen')
const dashboardScreen = document.getElementById('dashboard-screen')
const loginForm = document.getElementById('login-form')
const logoutBtn = document.getElementById('logout-btn')
const tokenKey = 'skyptoken'

const showScreen = (screen) => {
  loginScreen.classList.toggle('active', screen === 'login')
  dashboardScreen.classList.toggle('active', screen === 'dashboard')
}

const getHeaders = () => {
  const token = localStorage.getItem(tokenKey)
  return token ? { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` } : { 'Content-Type': 'application/json' }
}

const fetchDashboard = async () => {
  const res = await fetch('/dashboard', { headers: getHeaders() })
  if (!res.ok) throw new Error('Unable to load dashboard')
  return res.json()
}

const fetchAppointments = async () => {
  const res = await fetch('/appointments', { headers: getHeaders() })
  if (!res.ok) throw new Error('Unable to load appointments')
  return res.json()
}

const fetchPatients = async () => {
  const res = await fetch('/patients', { headers: getHeaders() })
  if (!res.ok) throw new Error('Unable to load patients')
  return res.json()
}

const renderDashboard = async () => {
  const stats = await fetchDashboard()
  document.getElementById('metric-patients').textContent = stats.patients
  document.getElementById('metric-appointments').textContent = stats.openAppointments
  document.getElementById('metric-alerts').textContent = stats.criticalAlerts
  document.getElementById('metric-wait').textContent = `${stats.averageWaitMins}`

  const appointments = await fetchAppointments()
  const appointmentsList = document.getElementById('appointments-list')
  appointmentsList.innerHTML = appointments.appointments
    .map((item) => `<div class="appointment"><strong>${item.time}</strong><span>${item.patient}</span><span class="status">${item.status}</span></div>`)
    .join('')

  const patients = await fetchPatients()
  const table = document.getElementById('patients-table')
  table.innerHTML = patients.patients
    .map(
      (p) => `<tr><td>${p.id}</td><td>${p.name}</td><td>${p.dob}</td><td>${p.status}</td></tr>`
    )
    .join('')
}

const login = async (username, password) => {
  const res = await fetch('/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  })
  if (!res.ok) {
    const error = await res.json()
    throw new Error(error.detail || 'Login failed')
  }
  return res.json()
}

loginForm.addEventListener('submit', async (event) => {
  event.preventDefault()
  const username = document.getElementById('username').value
  const password = document.getElementById('password').value
  try {
    const data = await login(username, password)
    localStorage.setItem(tokenKey, data.token)
    showScreen('dashboard')
    await renderDashboard()
  } catch (err) {
    alert(err.message)
  }
})

logoutBtn.addEventListener('click', () => {
  localStorage.removeItem(tokenKey)
  showScreen('login')
})

const start = async () => {
  const token = localStorage.getItem(tokenKey)
  if (token) {
    showScreen('dashboard')
    try {
      await renderDashboard()
    } catch (err) {
      showScreen('login')
    }
  } else {
    showScreen('login')
  }
}

start()
