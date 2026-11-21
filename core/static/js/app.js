// ==== CLAVES LOCALSTORAGE ====
const STORAGE_USER         = "siglet_user";
const STORAGE_ROLE         = "siglet_role";      // "alumno" | "admin"
const STORAGE_SOLICITUD    = "siglet_solicitud";
const STORAGE_PRESTAMOS    = "siglet_prestamos";
const STORAGE_ENDPOINT     = "siglet_endpoint_api";
const STORAGE_CONN_STATUS  = "siglet_conn_status";

// ==== INVENTARIO GLOBAL (TODOS LOS LABS) ====
const inventarioItems = [
    // Biomédica
    { id: 1, nombre: "TUBOS CAPILARES KIMAX", descripcion: "TUBOS CAPILARES", disponibles: 100, maxDias: 1, maxCantidad: 3, laboratorio: "Biomédica" },
    { id: 2, nombre: "AGITADORES", descripcion: "AGITADORES", disponibles: 7, maxDias: 1, maxCantidad: 1, laboratorio: "Biomédica" },
    { id: 3, nombre: "SENSOR DE PRESIÓN", descripcion: "SENSOR DE PRESIÓN", disponibles: 15, maxDias: 10, maxCantidad: 1, laboratorio: "Biomédica" },
    { id: 4, nombre: "SEMICONDUCTORES N-CHANNEL ZVN211A", descripcion: "SEMICONDUCTORES N-CHANNEL ENHANCEMENTMODE VERTICAL", disponibles: 10, maxDias: 5, maxCantidad: 1, laboratorio: "Biomédica" },
    // Electrónica
    { id: 5, nombre: "RESISTOR 2 W", descripcion: "RESISTENCIAS DE POTENCIA 2 W", disponibles: 50, maxDias: 7, maxCantidad: 10, laboratorio: "Electrónica" },
    { id: 6, nombre: "OPTOACOPLADOR HCNR200", descripcion: "OPTOACOPLADORES ANALÓGICOS DE ALTA LINEALIDAD", disponibles: 20, maxDias: 5, maxCantidad: 2, laboratorio: "Electrónica" },
    { id: 7, nombre: "OSCILOSCOPIO TEKTRONIX 100 MHz", descripcion: "OSCILOSCOPIO DE MESA", disponibles: 4, maxDias: 3, maxCantidad: 1, laboratorio: "Electrónica" },
    // Corte
    { id: 8, nombre: "DISCO DE CORTE METAL 4\"", descripcion: "DISCOS PARA CORTE EN FRÍO", disponibles: 30, maxDias: 2, maxCantidad: 5, laboratorio: "Corte" },
    { id: 9, nombre: "GUANTES ANTICORTE", descripcion: "GUANTES NIVEL 5", disponibles: 20, maxDias: 2, maxCantidad: 2, laboratorio: "Corte" },
    // Conformado
    { id: 10, nombre: "MATRIZ PARA DOBLADO", descripcion: "MATRIZ PARA PRENSA HIDRÁULICA", disponibles: 3, maxDias: 5, maxCantidad: 1, laboratorio: "Conformado" },
    { id: 11, nombre: "BROCAS HSS 10 mm", descripcion: "BROCAS PARA TALADRO DE COLUMNA", disponibles: 25, maxDias: 3, maxCantidad: 5, laboratorio: "Conformado" },
    // Materiales
    { id: 12, nombre: "PROBETAS DE ALUMINIO", descripcion: "PARA ENSAYO DE TENSIÓN", disponibles: 40, maxDias: 7, maxCantidad: 10, laboratorio: "Materiales" },
    { id: 13, nombre: "PROBETAS DE ACERO A36", descripcion: "PARA ENSAYO DE TENSIÓN", disponibles: 35, maxDias: 7, maxCantidad: 10, laboratorio: "Materiales" }
];

// ==== ESTADO EN MEMORIA ====
let solicitudItems    = [];
let prestamosGlobales = [];
let ENDPOINT_API      = "https://siglet-api-demo.universidad.edu/prestamos";
let currentCaptcha    = "";
let connStatus        = { bd: "idle", api: "idle", lastSync: "" };

// ==== UTILIDADES LOCALSTORAGE ====
function loadFromStorage(key, defaultValue) {
    try {
        const raw = localStorage.getItem(key);
        if (!raw) return defaultValue;
        return JSON.parse(raw);
    } catch {
        return defaultValue;
    }
}

function saveToStorage(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
}

// ==== INICIO GLOBAL ====
document.addEventListener("DOMContentLoaded", () => {
    const page = document.body.dataset.page || "login";

    // Cargar datos compartidos
    solicitudItems    = loadFromStorage(STORAGE_SOLICITUD, []);
    prestamosGlobales = loadFromStorage(STORAGE_PRESTAMOS, []);
    const savedEndpoint = localStorage.getItem(STORAGE_ENDPOINT);
    if (savedEndpoint) ENDPOINT_API = savedEndpoint;
    connStatus = loadFromStorage(STORAGE_CONN_STATUS, { bd: "idle", api: "idle", lastSync: "" });

    if (page === "login") {
        initLogin();
        return;
    }

    // Páginas del portal
    protectPortal(page);
    initCommonHeader();

    if (page === "inventario")  initInventarioPage();
    if (page === "solicitud")   initSolicitudPage();
    if (page === "prestamos")   initPrestamosPage();
    if (page === "config")      initConfigPage();
});

// ==== PROTECCIÓN POR ROL ====
function protectPortal(page) {
    const user = localStorage.getItem(STORAGE_USER);
    const role = localStorage.getItem(STORAGE_ROLE); // "alumno" | "admin"

    if (!user || !role) {
        window.location.href = "index.html";
        return;
    }

    // Alumno NO puede entrar a configuración
    if (role === "alumno") {
        const allowed = ["inventario", "solicitud", "prestamos"];
        if (!allowed.includes(page)) {
            window.location.href = "inventario.html";
        }
    }
}

// ==== HEADER COMÚN ====
function initCommonHeader() {
    const emailSpan = document.getElementById("user-email-display");
    const email = localStorage.getItem(STORAGE_USER) || "";
    const role  = localStorage.getItem(STORAGE_ROLE) || "";
    if (emailSpan) {
        const rolLabel = role === "admin" ? "Administrador" : "Alumno";
        emailSpan.textContent = `${email} · ${rolLabel}`;
    }

    const portalCartCount = document.getElementById("portal-cart-count");
    if (portalCartCount) portalCartCount.textContent = solicitudItems.length;

    const btnLogout = document.getElementById("btn-logout");
    if (btnLogout) {
        btnLogout.addEventListener("click", () => {
            localStorage.removeItem(STORAGE_USER);
            localStorage.removeItem(STORAGE_ROLE);
            window.location.href = "index.html";
        });
    }

    // Navegación por tabs
    const portalTabs = document.querySelectorAll(".portal-tab");
    portalTabs.forEach(tab => {
        tab.addEventListener("click", () => {
            const target = tab.dataset.target || "prestamos.html";
            const tabName = tab.dataset.tab || "";

            if (target === "inventario.html") {
                window.location.href = "inventario.html";
                return;
            }

            if (tabName) {
                window.location.href = `${target}?tab=${tabName}`;
            } else {
                window.location.href = target;
            }
        });
    });

    // Logo -> home según rol
    const btnHome = document.getElementById("btn-home");
    if (btnHome) {
        btnHome.addEventListener("click", () => {
            const role = localStorage.getItem(STORAGE_ROLE);
            if (role === "admin") {
                window.location.href = "prestamos.html?tab=activos";
            } else {
                window.location.href = "inventario.html";
            }
        });
    }

    // Carrito -> solicitud
    const portalCartBtn = document.getElementById("portal-cart-btn");
    if (portalCartBtn) {
        portalCartBtn.addEventListener("click", () => {
            window.location.href = "solicitud.html";
        });
    }
}

// ==== LOGIN (rol + captcha dinámico) ====
function initLogin() {
    const loginForm    = document.getElementById("login-form");
    const loginEmail   = document.getElementById("login-email");
    const loginPass    = document.getElementById("login-password");
    const loginCaptcha = document.getElementById("login-captcha");
    const loginError   = document.getElementById("login-error");
    const captchaText  = document.getElementById("captcha-text");

    if (!loginForm) return;

    generateCaptcha(captchaText);

    loginForm.addEventListener("submit", (e) => {
        e.preventDefault();

        const email   = loginEmail.value.trim();
        const pass    = loginPass.value.trim();
        const captcha = loginCaptcha.value.trim();
        const roleRadios = document.querySelectorAll('input[name="login-role"]');
        let role = "";
        roleRadios.forEach(r => { if (r.checked) role = r.value; });

        if (!role) {
            loginError.textContent = "Selecciona si eres Alumno o Administrador.";
            generateCaptcha(captchaText);
            loginCaptcha.value = "";
            return;
        }

        if (!email || !pass || !captcha) {
            loginError.textContent = "Completa usuario, contraseña y captcha.";
            generateCaptcha(captchaText);
            loginCaptcha.value = "";
            return;
        }

        if (captcha !== currentCaptcha) {
            loginError.textContent = "El texto del captcha no coincide. Inténtalo de nuevo.";
            generateCaptcha(captchaText);
            loginCaptcha.value = "";
            return;
        }

        loginError.textContent = "";
        localStorage.setItem(STORAGE_USER, email);
        localStorage.setItem(STORAGE_ROLE, role);

        if (role === "admin") {
            window.location.href = "prestamos.html?tab=activos";
        } else {
            window.location.href = "inventario.html";
        }
    });
}

function generateCaptcha(captchaTextElement) {
    const chars = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789";
    let code = "";
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    currentCaptcha = code;
    if (captchaTextElement) captchaTextElement.textContent = code;
}

// ==== INVENTARIO ====
function initInventarioPage() {
    const labButtons      = document.querySelectorAll(".lab-btn[data-lab]");
    const inventarioCards = document.getElementById("inventario-cards");
    const searchInput     = document.getElementById("portal-search-input");
    const searchBtn       = document.getElementById("portal-search-btn");
    const portalCartCount = document.getElementById("portal-cart-count");

    let labActivo = "Biomédica";
    renderInventario(labActivo, "");

    labButtons.forEach(btn => {
        btn.addEventListener("click", () => {
            labButtons.forEach(b => b.classList.remove("lab-btn--active"));
            btn.classList.add("lab-btn--active");
            labActivo = btn.dataset.lab;
            const texto = searchInput ? searchInput.value : "";
            renderInventario(labActivo, texto);
        });
    });

    if (searchInput) {
        const aplicarFiltro = () => renderInventario(labActivo, searchInput.value);
        searchInput.addEventListener("input", aplicarFiltro);
        if (searchBtn) searchBtn.addEventListener("click", aplicarFiltro);
    }

    if (inventarioCards) {
        inventarioCards.addEventListener("click", (e) => {
            const btn = e.target;
            if (!btn.classList.contains("btn-add-item")) return;

            const id   = Number(btn.dataset.id);
            const item = inventarioItems.find(i => i.id === id);
            if (!item) return;

            const existente = solicitudItems.find(s => s.idItem === id);
            if (existente) {
                if (existente.cantidadSolicitada < item.maxCantidad) {
                    existente.cantidadSolicitada++;
                } else {
                    alert("Ya alcanzaste la cantidad máxima para este material.");
                    return;
                }
            } else {
                solicitudItems.push({
                    idItem: item.id,
                    descripcion: item.nombre,
                    laboratorio: item.laboratorio,
                    cantidadSolicitada: 1,
                    fechaSolicitud: "Sin solicitar",
                    fechaEntrega: calcularFechaEntrega(item.maxDias)
                });
            }

            saveToStorage(STORAGE_SOLICITUD, solicitudItems);
            if (portalCartCount) portalCartCount.textContent = solicitudItems.length;
        });
    }
}

function renderInventario(lab, filtroTexto) {
    const cont = document.getElementById("inventario-cards");
    if (!cont) return;

    const texto = (filtroTexto || "").toLowerCase().trim();

    const items = inventarioItems.filter(item => {
        const mismoLab = item.laboratorio === lab;
        const coincide = item.nombre.toLowerCase().includes(texto) ||
                         item.descripcion.toLowerCase().includes(texto);
        return mismoLab && coincide;
    });

    if (!items.length) {
        cont.innerHTML = "<p>No hay materiales para este laboratorio / filtro.</p>";
        return;
    }

    cont.innerHTML = items.map(item => `
        <article class="item-card">
            <div>
                <h3>${item.nombre}</h3>
                <p class="item-main-text"><span class="item-label">Disponibles:</span> ${item.disponibles.toFixed(2)}</p>
                <p class="item-main-text">${item.descripcion}</p>
                <p class="item-main-text"><span class="item-label">Días máximos de préstamo:</span> ${item.maxDias}</p>
                <p class="item-main-text"><span class="item-label">Cantidad máxima a prestar:</span> ${item.maxCantidad}</p>
                <p class="item-lab">${item.laboratorio}</p>
            </div>
            <div class="item-footer">
                <button class="btn-add-item" data-id="${item.id}">Añadir</button>
            </div>
        </article>
    `).join("");
}

// ==== SOLICITUD (CARRITO) ====
function initSolicitudPage() {
    const tablaSolicitud   = document.getElementById("tabla-solicitud");
    const portalCartCount  = document.getElementById("portal-cart-count");
    const btnSolicitar     = document.getElementById("btn-solicitar-material");

    renderSolicitudTabla(tablaSolicitud);
    if (portalCartCount) portalCartCount.textContent = solicitudItems.length;

    if (tablaSolicitud) {
        tablaSolicitud.addEventListener("click", (e) => {
            const btn = e.target;
            if (!btn.classList.contains("btn-delete")) return;
            const idx = Number(btn.dataset.index);
            if (idx >= 0 && idx < solicitudItems.length) {
                solicitudItems.splice(idx, 1);
                saveToStorage(STORAGE_SOLICITUD, solicitudItems);
                renderSolicitudTabla(tablaSolicitud);
                if (portalCartCount) portalCartCount.textContent = solicitudItems.length;
            }
        });
    }

    if (btnSolicitar) {
        btnSolicitar.addEventListener("click", () => {
            if (!solicitudItems.length) {
                alert("No tienes materiales en tu solicitud.");
                return;
            }
            alert("En la versión conectada a MySQL/AWS aquí se enviará la solicitud oficial.");
        });
    }
}

function renderSolicitudTabla(tabla) {
    if (!tabla) return;

    if (!solicitudItems.length) {
        tabla.innerHTML = `
            <tr class="placeholder-row">
                <td colspan="6">No hay materiales en tu solicitud.</td>
            </tr>
        `;
        return;
    }

    tabla.innerHTML = solicitudItems.map((item, idx) => `
        <tr>
            <td>${item.cantidadSolicitada}</td>
            <td>${item.descripcion}</td>
            <td>${item.laboratorio}</td>
            <td>${item.fechaSolicitud}</td>
            <td>${item.fechaEntrega}</td>
            <td><button class="btn-delete" data-index="${idx}">🗑</button></td>
        </tr>
    `).join("");
}

// ==== PRÉSTAMOS (ALUMNO: SOLO CONSULTA SUS REGISTROS) ====
function initPrestamosPage() {
    const btnProbarConexion   = document.getElementById("btn-probar-conexion");
    const btnCargarDatos      = document.getElementById("btn-cargar-datos");
    const estadoBD            = document.getElementById("estado-bd");
    const estadoAPI           = document.getElementById("estado-api");
    const ultimaActualizacion = document.getElementById("ultima-actualizacion");
    const tablaRegistros      = document.getElementById("tabla-registros");
    const searchInput         = document.getElementById("portal-search-input");
    const searchBtn           = document.getElementById("portal-search-btn");
    const portalCartCount     = document.getElementById("portal-cart-count");

    const formPrestamo        = document.getElementById("form-prestamo");
    const correoUsuarioInput  = document.getElementById("correo-usuario");
    const rolUsuarioSelect    = document.getElementById("rol-usuario");
    const laboratorioSelect   = document.getElementById("laboratorio");
    const equipoInput         = document.getElementById("equipo");
    const fechaInicioInput    = document.getElementById("fecha-inicio");
    const horaInicioInput     = document.getElementById("hora-inicio");
    const horaFinInput        = document.getElementById("hora-fin");
    const observacionesInput  = document.getElementById("observaciones");

    const role      = localStorage.getItem(STORAGE_ROLE);
    const emailUser = localStorage.getItem(STORAGE_USER) || "";

    // Ocultar secciones solo admin para alumnos
    if (role === "alumno") {
        const adminSections = document.querySelectorAll(".admin-only-section");
        adminSections.forEach(sec => sec.classList.add("hidden"));
    }

    // Determinar tab actual
    const params = new URLSearchParams(window.location.search);
    let currentTab = params.get("tab") || "activos";

    // Activar tab en header
    const headerTabs = document.querySelectorAll(".portal-tab");
    headerTabs.forEach(t => {
        if (t.dataset.target === "prestamos.html" && t.dataset.tab === currentTab) {
            t.classList.add("portal-tab--active");
        }
    });

    // Prestamos base según rol
    let baseList = [];
    if (role === "admin") {
        baseList = prestamosGlobales;
    } else {
        baseList = prestamosGlobales.filter(p => p.correo === emailUser);
    }

    // Cargar estado de conexión persistente
    if (estadoBD && estadoAPI && ultimaActualizacion && connStatus) {
        if (connStatus.bd === "ok") {
            estadoBD.textContent = "MySQL disponible";
            estadoBD.className = "status-pill status-pill--ok";
        } else if (connStatus.bd === "error") {
            estadoBD.textContent = "Error BD";
            estadoBD.className = "status-pill status-pill--error";
        } else {
            estadoBD.textContent = "Sin probar";
            estadoBD.className = "status-pill status-pill--idle";
        }

        if (connStatus.api === "ok") {
            estadoAPI.textContent = "API en línea";
            estadoAPI.className = "status-pill status-pill--ok";
        } else if (connStatus.api === "error") {
            estadoAPI.textContent = "Error API";
            estadoAPI.className = "status-pill status-pill--error";
        } else {
            estadoAPI.textContent = "Sin probar";
            estadoAPI.className = "status-pill status-pill--idle";
        }

        ultimaActualizacion.textContent = connStatus.lastSync || "—";
    }

    // Render inicial
    let mostrados = filtrarPrestamosPorTab(baseList, currentTab);
    pintarTablaPrestamos(tablaRegistros, mostrados);
    if (portalCartCount) portalCartCount.textContent = solicitudItems.length;

    // Probar conexión (solo hace algo si admin y botones visibles)
    if (btnProbarConexion && estadoBD && estadoAPI && ultimaActualizacion && role === "admin") {
        btnProbarConexion.addEventListener("click", async () => {
            estadoBD.textContent = "Probando conexión…";
            estadoAPI.textContent = "Probando conexión…";
            estadoBD.className = "status-pill status-pill--idle";
            estadoAPI.className = "status-pill status-pill--idle";

            try {
                await new Promise(r => setTimeout(r, 800));
                estadoBD.textContent = "MySQL disponible";
                estadoAPI.textContent = "API en línea";
                estadoBD.className = "status-pill status-pill--ok";
                estadoAPI.className = "status-pill status-pill--ok";
                const now = new Date().toLocaleString();
                ultimaActualizacion.textContent = now;

                connStatus = { bd: "ok", api: "ok", lastSync: now };
                saveToStorage(STORAGE_CONN_STATUS, connStatus);
            } catch {
                estadoBD.textContent = "Error BD";
                estadoAPI.textContent = "Error API";
                estadoBD.className = "status-pill status-pill--error";
                estadoAPI.className = "status-pill status-pill--error";

                connStatus = { bd: "error", api: "error", lastSync: "" };
                saveToStorage(STORAGE_CONN_STATUS, connStatus);
            }
        });
    }

    // Cargar ejemplos
    if (btnCargarDatos && role === "admin") {
        btnCargarDatos.addEventListener("click", async () => {
            if (tablaRegistros) {
                tablaRegistros.innerHTML = `
                    <tr class="placeholder-row">
                        <td colspan="9">Cargando préstamos de ejemplo…</td>
                    </tr>
                `;
            }

            await new Promise(r => setTimeout(r, 900));

            const ejemplos = [
                { id: 1, correo: "ricardo.ponce@universidad.edu", rol: "Estudiante", laboratorio: "LAB-TIC-01",  equipo: "Osciloscopio Tektronix 1", fechaPrestamo: "2025-11-18 09:00", fechaDevolucion: "2025-11-18 11:00", estado: "CERRADO", incidencia: "Sin incidencias" },
                { id: 2, correo: "edgar.lopez@universidad.edu",  rol: "Profesor",   laboratorio: "LAB-ELECT-02", equipo: "Fuente de poder 30V",      fechaPrestamo: "2025-11-17 08:30", fechaDevolucion: "2025-11-17 10:15", estado: "VENCIDO", incidencia: "Entrega fuera de tiempo." },
                { id: 3, correo: "aine@universidad.edu",          rol: "Estudiante", laboratorio: "LAB-TIC-01",  equipo: "Laptop laboratorio 05",  fechaPrestamo: "2025-11-18 14:00", fechaDevolucion: "-",                 estado: "EN CURSO", incidencia: "Sin incidencias reportadas." },
                { id: 4, correo: "ricardo.ponce@universidad.edu", rol: "Estudiante", laboratorio: "LAB-ELECT-02", equipo: "Fuente de poder 0-30V",  fechaPrestamo: "2025-11-10 10:00", fechaDevolucion: "-",                 estado: "ADEUDO", incidencia: "Equipo no devuelto." }
            ];

            const ids = new Set(prestamosGlobales.map(p => p.id));
            ejemplos.forEach(p => { if (!ids.has(p.id)) prestamosGlobales.push(p); });

            saveToStorage(STORAGE_PRESTAMOS, prestamosGlobales);

            baseList = (role === "admin")
                ? prestamosGlobales
                : prestamosGlobales.filter(p => p.correo === emailUser);

            mostrados = filtrarPrestamosPorTab(baseList, currentTab);
            pintarTablaPrestamos(tablaRegistros, mostrados);

            const now = new Date().toLocaleString();
            if (ultimaActualizacion) ultimaActualizacion.textContent = now;
        });
    }

    // Registrar préstamo manual (solo admin)
    let contador = prestamosGlobales.length ? Math.max(...prestamosGlobales.map(p => p.id)) : 0;
    if (formPrestamo && role === "admin") {
        formPrestamo.addEventListener("submit", (e) => {
            e.preventDefault();

            const correo = correoUsuarioInput.value.trim();
            const rol    = rolUsuarioSelect.value;
            const lab    = laboratorioSelect.value;
            const eq     = equipoInput.value.trim();
            const fecha  = fechaInicioInput.value;
            const hi     = horaInicioInput.value;
            const hf     = horaFinInput.value;
            const obs    = observacionesInput.value.trim();

            if (!correo || !rol || !lab || !eq || !fecha || !hi || !hf) {
                alert("Completa todos los campos obligatorios.");
                return;
            }

            contador++;
            const prestamo = {
                id: contador,
                correo,
                rol,
                laboratorio: lab,
                equipo: eq,
                fechaPrestamo: `${fecha} ${hi}`,
                fechaDevolucion: `${fecha} ${hf}`,
                estado: "EN CURSO",
                incidencia: obs || "Sin incidencias registradas."
            };

            prestamosGlobales.push(prestamo);
            saveToStorage(STORAGE_PRESTAMOS, prestamosGlobales);

            baseList = (role === "admin")
                ? prestamosGlobales
                : prestamosGlobales.filter(p => p.correo === emailUser);

            mostrados = filtrarPrestamosPorTab(baseList, currentTab);
            pintarTablaPrestamos(tablaRegistros, mostrados);
            formPrestamo.reset();
            alert("Préstamo registrado (modo prueba, localStorage).");
        });
    }

    // Buscador en header (filtra sobre la pestaña actual)
    if (searchInput) {
        const aplicarFiltro = () => {
            const t = searchInput.value.toLowerCase().trim();
            const baseTab = filtrarPrestamosPorTab(baseList, currentTab);
            const filtrados = baseTab.filter(p =>
                p.correo.toLowerCase().includes(t) ||
                p.rol.toLowerCase().includes(t) ||
                p.laboratorio.toLowerCase().includes(t) ||
                p.equipo.toLowerCase().includes(t) ||
                String(p.id).includes(t)
            );
            pintarTablaPrestamos(tablaRegistros, filtrados);
        };
        searchInput.addEventListener("input", aplicarFiltro);
        if (searchBtn) searchBtn.addEventListener("click", aplicarFiltro);
    }
}

function filtrarPrestamosPorTab(lista, tab) {
    const t = (tab || "").toLowerCase();
    if (t === "activos") {
        return lista.filter(p => p.estado === "EN CURSO" || p.estado === "ACTIVO");
    } else if (t === "vencidos") {
        return lista.filter(p => p.estado === "VENCIDO");
    } else if (t === "previos") {
        return lista.filter(p => p.estado === "CERRADO");
    } else if (t === "adeudos") {
        return lista.filter(p => p.estado === "ADEUDO");
    }
    return lista;
}

function pintarTablaPrestamos(tabla, prestamos) {
    if (!tabla) return;

    if (!prestamos.length) {
        tabla.innerHTML = `
            <tr class="placeholder-row">
                <td colspan="9">Sin préstamos registrados.</td>
            </tr>
        `;
        return;
    }

    tabla.innerHTML = prestamos.map(p => `
        <tr>
            <td>${p.id}</td>
            <td>${p.correo}</td>
            <td>${p.rol}</td>
            <td>${p.laboratorio}</td>
            <td>${p.equipo}</td>
            <td>${p.fechaPrestamo}</td>
            <td>${p.fechaDevolucion}</td>
            <td>${p.estado}</td>
            <td>${p.incidencia}</td>
        </tr>
    `).join("");
}

// ==== CONFIGURACIÓN ====
function initConfigPage() {
    const endpointInput   = document.getElementById("endpoint-api");
    const btnGuardar      = document.getElementById("btn-guardar-config");
    const portalCartCount = document.getElementById("portal-cart-count");

    if (endpointInput) endpointInput.value = ENDPOINT_API;
    if (portalCartCount) portalCartCount.textContent = solicitudItems.length;

    if (btnGuardar) {
        btnGuardar.addEventListener("click", () => {
            const val = (endpointInput.value || "").trim();
            if (!val) {
                alert("Escribe un endpoint válido.");
                return;
            }
            ENDPOINT_API = val;
            localStorage.setItem(STORAGE_ENDPOINT, val);
            alert("Configuración guardada en el navegador (modo prueba).");
        });
    }
}

// ==== AUXILIAR FECHA ENTREGA ====
function calcularFechaEntrega(maxDias) {
    const d = new Date();
    const dias = maxDias && maxDias > 0 ? maxDias : 1;
    d.setDate(d.getDate() + dias);
    return d.toISOString().split("T")[0];
}
