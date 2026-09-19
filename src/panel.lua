-- Lee panel.txt (lo escribe el hook de Claude Code) y pinta una fila por sesión.
-- Dos modos: "completo" (título + filas) y "minimo" (solo puntos; se despliega al pasar el ratón).
-- ESTE es el original, en UTF-8. generar-skin.js lo copia a la skin convertido a UTF-16 LE,
-- que es lo que Rainmeter necesita para mostrar bien los acentos. No editar la copia de la skin.

local colores = {
  rojo     = '235,70,60',
  amarillo = '240,190,40',
  verde    = '70,200,110',
  gris     = '150,150,150',
}
local urgencia = { rojo = 1, amarillo = 2, verde = 3, gris = 4 }
local MINUTOS_VERDE = 10      -- después, una sesión terminada se muestra en gris como "Pausado"
local TICKS_PIDS = 20         -- cada cuántas actualizaciones se piden los claude.exe vivos (20 x 0,5 s = 10 s)

local tick = 0
local expandido = false

-- avisos.txt lo lee hook.js: "0" = solo monitorizar, sin notificaciones. Si no existe, se avisa.
function leerAvisos()
  local f = io.open(archivoAvisos, 'r')
  if not f then return true end
  local valor = f:read('*l')
  f:close()
  return valor ~= '0'
end

local function pintarInterruptor()
  local fondo = avisos and '70,200,110,255' or '90,90,96,255'
  local bola = avisos and 21 or 7
  SKIN:Bang('!SetOption', 'Interruptor', 'Shape', 'Rectangle 0,0,28,14,7 | Fill Color ' .. fondo .. ' | StrokeWidth 0')
  SKIN:Bang('!SetOption', 'Interruptor', 'Shape2', 'Ellipse ' .. bola .. ',7,5 | Fill Color 255,255,255,255 | StrokeWidth 0')
  SKIN:Bang('!SetOption', 'Interruptor', 'ToolTipText',
    avisos and 'Avisos activados. Clic para solo monitorizar.' or 'Solo monitorizar. Clic para activar los avisos.')
end

function Initialize()
  archivo = SKIN:GetVariable('Archivo')
  enfocar = SKIN:GetVariable('Enfocar')
  maxFilas = tonumber(SKIN:GetVariable('MaxFilas'))
  altoFila = tonumber(SKIN:GetVariable('AltoFila'))
  margen = tonumber(SKIN:GetVariable('Margen'))
  ancho = tonumber(SKIN:GetVariable('Ancho'))
  altoTitulo = tonumber(SKIN:GetVariable('AltoTitulo'))
  modo = SKIN:GetVariable('Modo')
  archivoAvisos = SKIN:GetVariable('ArchivoAvisos')
  avisos = leerAvisos()
  medidaPids = SKIN:GetMeasure('MeasurePids')
  SKIN:Bang('!CommandMeasure', 'MeasurePids', 'Run')
end

local function leerSesiones()
  local sesiones = {}
  local f = io.open(archivo, 'r')
  if not f then return sesiones end
  local vivos = medidaPids:GetStringValue()
  for linea in f:lines() do
    local c = {}
    for campo in (linea .. '\t'):gmatch('([^\t]*)\t') do table.insert(c, campo) end
    if #c >= 5 then
      local pid = tonumber(c[6]) or 0
      -- Si ya se sabe qué claude.exe están vivos y el de esta sesión no está, su ventana se cerró.
      local viva = pid == 0 or not vivos:find(',', 1, true) or vivos:find(',' .. pid .. ',', 1, true)
      if viva then
        table.insert(sesiones, { estado = c[1], nombre = c[2], detalle = c[3], ts = tonumber(c[4]) or 0,
                                 carpeta = c[5], inicio = tonumber(c[7]) or 0 })
      end
    end
  end
  f:close()
  return sesiones
end

local function hace(segundos)
  if segundos < 60 then return 'ahora' end
  local min = math.floor(segundos / 60)
  if min < 60 then return min .. ' min' end
  return math.floor(min / 60) .. ' h'
end

local function opcion(meter, clave, valor)
  SKIN:Bang('!SetOption', meter, clave, valor)
end

function Update()
  tick = tick + 1
  if tick % TICKS_PIDS == 0 then SKIN:Bang('!CommandMeasure', 'MeasurePids', 'Run') end
  local parpadeo = tick % 2 == 0

  local ahora = os.time()
  local sesiones = leerSesiones()
  for _, s in ipairs(sesiones) do
    if s.estado == 'verde' and ahora - s.ts > MINUTOS_VERDE * 60 then
      s.estado = 'gris'
      s.detalle = 'Pausado'
    end
  end
  table.sort(sesiones, function(a, b)
    local ua, ub = urgencia[a.estado] or 5, urgencia[b.estado] or 5
    if ua ~= ub then return ua < ub end
    return a.inicio < b.inicio
  end)

  local n = math.min(#sesiones, maxFilas)
  local completo = modo ~= 'minimo' or expandido

  for i = 1, maxFilas do
    local s = sesiones[i]
    if s then
      local color = colores[s.estado] or colores.gris
      local alfa = (s.estado == 'rojo' and parpadeo) and '70' or '255'
      opcion('Punto' .. i, 'Shape', 'Ellipse 6,6,5 | Fill Color ' .. color .. ',' .. alfa .. ' | StrokeWidth 0')

      if completo then
        local y = margen + altoTitulo + (i - 1) * altoFila
        opcion('Punto' .. i, 'X', margen + 8)
        opcion('Punto' .. i, 'Y', y + 6)
        local alfaFondo = (s.estado == 'rojo' and parpadeo) and '25' or '45'
        if s.estado == 'gris' then alfaFondo = '0' end
        opcion('FondoFila' .. i, 'Y', y)
        opcion('FondoFila' .. i, 'Shape',
          'Rectangle 0,0,' .. (ancho - 2 * margen) .. ',' .. (altoFila - 3) .. ',4 | Fill Color ' ..
          color .. ',' .. alfaFondo .. ' | StrokeWidth 0')
        opcion('Nombre' .. i, 'Y', y + 1)
        opcion('Detalle' .. i, 'Y', y + 3)
        opcion('Hace' .. i, 'Y', y + 4)
        opcion('Nombre' .. i, 'Text', s.nombre)
        opcion('Detalle' .. i, 'Text', s.detalle)
        opcion('Hace' .. i, 'Text', hace(ahora - s.ts))
        local abrir = '["' .. enfocar .. '" "' .. s.carpeta .. '"]'
        opcion('FondoFila' .. i, 'LeftMouseUpAction', abrir)
        opcion('Nombre' .. i, 'LeftMouseUpAction', abrir)
        opcion('Detalle' .. i, 'LeftMouseUpAction', abrir)
        SKIN:Bang('!ShowMeterGroup', 'Fila' .. i)
      else
        opcion('Punto' .. i, 'X', margen + (i - 1) * 18)
        opcion('Punto' .. i, 'Y', margen)
        SKIN:Bang('!HideMeterGroup', 'Fila' .. i)
        SKIN:Bang('!ShowMeter', 'Punto' .. i)
      end
    else
      SKIN:Bang('!HideMeterGroup', 'Fila' .. i)
    end
  end

  local anchoFondo, altoFondo
  if completo then
    SKIN:Bang('!ShowMeter', 'Titulo')
    SKIN:Bang('!ShowMeter', 'EtiquetaAvisos')
    SKIN:Bang('!ShowMeter', 'Interruptor')
    pintarInterruptor()
    if n == 0 then SKIN:Bang('!ShowMeter', 'SinSesiones') else SKIN:Bang('!HideMeter', 'SinSesiones') end
    anchoFondo = ancho
    altoFondo = altoTitulo + math.max(n, 1) * altoFila + 2 * margen - 3
  else
    SKIN:Bang('!HideMeter', 'Titulo')
    SKIN:Bang('!HideMeter', 'EtiquetaAvisos')
    SKIN:Bang('!HideMeter', 'Interruptor')
    SKIN:Bang('!HideMeter', 'SinSesiones')
    anchoFondo = math.max(n, 1) * 18 + 2 * margen - 6
    altoFondo = 12 + 2 * margen
  end
  opcion('Fondo', 'Shape', 'Rectangle 0,0,' .. anchoFondo .. ',' .. altoFondo .. ',8 | Fill Color 18,18,22,200 | StrokeWidth 0')

  SKIN:Bang('!UpdateMeter', '*')
  SKIN:Bang('!Redraw')
  return n
end

-- Llamadas desde la skin

function Expandir(valor)
  expandido = valor
  Update()
end

function CambiarAvisos()
  avisos = not avisos
  local f = io.open(archivoAvisos, 'w')
  if f then
    f:write(avisos and '1' or '0')
    f:close()
  end
  Update()
end

function CambiarModo()
  modo = (modo == 'minimo') and 'completo' or 'minimo'
  SKIN:Bang('!WriteKeyValue', 'Variables', 'Modo', modo)
  Update()
end
