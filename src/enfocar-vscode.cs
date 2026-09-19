// Trae al frente la ventana de VS Code que tiene abierta una carpeta.
// Uso: enfocar-vscode.exe "C:\ruta\proyecto"   o   enfocar-vscode.exe "panelclaude://C:/ruta/proyecto"
// Si no hay ninguna ventana con esa carpeta, la abre con el comando "code".
// Compilar: csc /target:winexe /out:enfocar-vscode.exe enfocar-vscode.cs
using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

class EnfocarVsCode
{
    delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr hWnd, StringBuilder s, int max);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr hWnd);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr pid);
    [DllImport("kernel32.dll")] static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("user32.dll")] static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);

    const string SUFIJO = " - Visual Studio Code";

    static void Main(string[] args)
    {
        if (args.Length == 0) return;
        string carpeta = args[0];
        if (carpeta.StartsWith("panelclaude:", StringComparison.OrdinalIgnoreCase))
            carpeta = Uri.UnescapeDataString(carpeta.Substring("panelclaude:".Length).TrimStart('/'));
        carpeta = carpeta.Replace('/', '\\').TrimEnd('\\');
        string nombre = Path.GetFileName(carpeta);

        IntPtr encontrada = IntPtr.Zero;
        EnumWindows((h, l) =>
        {
            if (!IsWindowVisible(h)) return true;
            var sb = new StringBuilder(512);
            GetWindowText(h, sb, sb.Capacity);
            string t = sb.ToString();
            int fin = t.LastIndexOf(SUFIJO, StringComparison.Ordinal);
            if (fin < 0) return true;
            string resto = t.Substring(0, fin);
            // El título es "<fichero> - <carpeta>" o solo "<carpeta>".
            if (resto == nombre || resto.EndsWith(" - " + nombre, StringComparison.Ordinal))
            {
                encontrada = h;
                return false;
            }
            return true;
        }, IntPtr.Zero);

        if (encontrada == IntPtr.Zero)
        {
            var psi = new ProcessStartInfo("cmd.exe", "/c code \"" + carpeta + "\"");
            psi.CreateNoWindow = true;
            psi.UseShellExecute = false;
            Process.Start(psi);
            return;
        }

        if (IsIconic(encontrada)) ShowWindow(encontrada, 9); // SW_RESTORE

        // Windows solo deja pasar al frente una ventana si el proceso que lo pide tiene permiso.
        // Pulsar y soltar Alt y enlazarse al hilo de la ventana activa lo concede.
        uint hiloActivo = GetWindowThreadProcessId(GetForegroundWindow(), IntPtr.Zero);
        uint hiloPropio = GetCurrentThreadId();
        keybd_event(0x12, 0, 0, UIntPtr.Zero);
        keybd_event(0x12, 0, 2, UIntPtr.Zero);
        AttachThreadInput(hiloPropio, hiloActivo, true);
        SetForegroundWindow(encontrada);
        AttachThreadInput(hiloPropio, hiloActivo, false);
    }
}
