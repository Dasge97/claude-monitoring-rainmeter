// Utilidades de procesos para el panel de sesiones de Claude.
//   panel-util.exe padre <pid>   -> PID del claude.exe antecesor de <pid> (0 si no hay)
//   panel-util.exe pids          -> PIDs de todos los claude.exe vivos, en formato ",12,34,"
//   panel-util.exe activa <carpeta> -> 1 si la ventana con el foco es la de VS Code con esa carpeta, 0 si no
// Compilar: csc /target:exe /out:panel-util.exe panel-util.cs
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

class PanelUtil
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct PROCESSENTRY32W
    {
        public uint dwSize, cntUsage, th32ProcessID;
        public IntPtr th32DefaultHeapID;
        public uint th32ModuleID, cntThreads, th32ParentProcessID;
        public int pcPriClassBase;
        public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szExeFile;
    }
    [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr CreateToolhelp32Snapshot(uint flags, uint pid);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern bool Process32FirstW(IntPtr snap, ref PROCESSENTRY32W e);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] static extern bool Process32NextW(IntPtr snap, ref PROCESSENTRY32W e);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder s, int max);

    // Mismo criterio que enfocar-vscode.cs: el título es "<fichero> - <carpeta> - Visual Studio Code"
    // o "<carpeta> - Visual Studio Code".
    static bool EsVentanaDe(string titulo, string nombreCarpeta)
    {
        const string SUFIJO = " - Visual Studio Code";
        int fin = titulo.LastIndexOf(SUFIJO, StringComparison.Ordinal);
        if (fin < 0) return false;
        string resto = titulo.Substring(0, fin);
        return resto == nombreCarpeta || resto.EndsWith(" - " + nombreCarpeta, StringComparison.Ordinal);
    }

    // PID -> (PID del padre, nombre del ejecutable)
    static Dictionary<uint, KeyValuePair<uint, string>> Procesos()
    {
        var r = new Dictionary<uint, KeyValuePair<uint, string>>();
        IntPtr snap = CreateToolhelp32Snapshot(0x2, 0);
        var e = new PROCESSENTRY32W();
        e.dwSize = (uint)Marshal.SizeOf(typeof(PROCESSENTRY32W));
        if (Process32FirstW(snap, ref e))
            do { r[e.th32ProcessID] = new KeyValuePair<uint, string>(e.th32ParentProcessID, e.szExeFile.ToLowerInvariant()); }
            while (Process32NextW(snap, ref e));
        CloseHandle(snap);
        return r;
    }

    static void Main(string[] args)
    {
        if (args.Length == 0) return;
        if (args[0] == "activa" && args.Length > 1)
        {
            var sbTitulo = new StringBuilder(512);
            GetWindowText(GetForegroundWindow(), sbTitulo, sbTitulo.Capacity);
            string nombre = System.IO.Path.GetFileName(args[1].Replace('/', '\\').TrimEnd('\\'));
            Console.Write(EsVentanaDe(sbTitulo.ToString(), nombre) ? "1" : "0");
            return;
        }
        var procs = Procesos();
        if (args[0] == "pids")
        {
            var sb = new StringBuilder(",");
            foreach (var p in procs) if (p.Value.Value == "claude.exe") sb.Append(p.Key).Append(',');
            Console.Write(sb.ToString());
        }
        else if (args[0] == "padre" && args.Length > 1)
        {
            uint pid = uint.Parse(args[1]);
            for (int i = 0; i < 20 && procs.ContainsKey(pid); i++)
            {
                if (procs[pid].Value == "claude.exe") { Console.Write(pid); return; }
                pid = procs[pid].Key;
            }
            Console.Write(0);
        }
    }
}
