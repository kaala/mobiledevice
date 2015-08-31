using System;
using System.Collections;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using CoreFoundation;
using Microsoft.Win32;

namespace mobiledevice
{
    class MobileDevice
    {
        // 常量

        public const string CFBundleIdentifier = "CFBundleIdentifier";
        public const string ApplicationType = "ApplicationType";
        public const string CFBundleName = "CFBundleName";
        public const string CFBundleDisplayName = "CFBundleDisplayName";
        public const string CFBundleShortVersionString = "CFBundleShortVersionString";
        public const string CFBundleVersion = "CFBundleVersion";

        public const string ProfileMetadata = "ProfileMetadata";
        public const string OrderedIdentifiers = "OrderedIdentifiers";
        public const string PayloadDisplayName = "PayloadDisplayName";
        public const string PayloadOrganization = "PayloadOrganization";
        public const string PayloadIdentifier = "PayloadIdentifier";

        // 设备通知

        //[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi, Pack = 1)]
        [StructLayout(LayoutKind.Sequential)]
        struct AMDeviceNotificationCallbackInfo
        {
            public IntPtr dev
            {
                get
                {
                    return dev_ptr;
                }
            }
            private IntPtr dev_ptr;
            public int msg;
        }

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        delegate void DeviceNotificationCallback(ref AMDeviceNotificationCallbackInfo callback_info, uint cookie);

        static int DEVICE_CONNECTED = 1;
        static int DEVICE_DISCONNECTED = 2;

        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceNotificationSubscribe(DeviceNotificationCallback callback, uint unused0, uint unused1, uint cookie, out IntPtr am_device_notification_ptr);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceNotificationUnsubscribe(IntPtr am_device_notification_ptr);

        // 设备属性

        static int DEVICE_INTERFACE_USB = 1;
        //static int DEVICE_INTERFACE_WIFI = 2;

        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceGetInterfaceType(IntPtr device);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static IntPtr AMDeviceCopyDeviceIdentifier(IntPtr device);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        static extern IntPtr AMDeviceCopyValue(IntPtr device, IntPtr domain, IntPtr key);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        static extern int AMDeviceSetValue(IntPtr device, IntPtr domain, IntPtr key, IntPtr value);

        public static string GetDeviceIdentifier(IntPtr device)
        {
            IntPtr p = AMDeviceCopyDeviceIdentifier(device);
            CFString str = new CFString(p);
            return str.ToString();
        }

        public static bool UpdateTime(IntPtr device, double time)
        {
            int sec = Convert.ToInt32(time);
            CFString domain = new CFString("NULL");
            CFString key = new CFString("TimeIntervalSince1970");
            IntPtr p = AMDeviceCopyValue(device, domain, key);
            string n = new CFNumber(p).ToString();
            CFNumber value = new CFNumber(sec);
            return AMDeviceSetValue(device, domain, key, value) == NO_ERR;
        }

        // 设备连接

        public static int NO_ERR = 0;

        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceConnect(IntPtr device);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceIsPaired(IntPtr device);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDevicePair(IntPtr device);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceValidatePairing(IntPtr device);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceStartSession(IntPtr device);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceStopSession(IntPtr device);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceDisconnect(IntPtr device);

        public static bool Connect(IntPtr device)
        {
            return AMDeviceConnect(device) == NO_ERR;
        }

        public static bool IsPaired(IntPtr device)
        {
            return AMDeviceIsPaired(device) != 0;
        }

        public static bool PairDevice(IntPtr device)
        {
            return AMDevicePair(device) == NO_ERR;
        }

        public static bool ValidatePairing(IntPtr device)
        {
            return AMDeviceValidatePairing(device) == NO_ERR;
        }

        public static bool StartSession(IntPtr device)
        {
            return AMDeviceStartSession(device) == NO_ERR;
        }

        public static bool StopSession(IntPtr device)
        {
            return AMDeviceStopSession(device) == NO_ERR;
        }

        public static bool Disconnect(IntPtr device)
        {
            return AMDeviceDisconnect(device) == NO_ERR;
        }

        // 服务

        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceStartService(IntPtr device, IntPtr svcName, out int sock);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceLookupApplications(IntPtr device, int unused0, out IntPtr apps);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceSecureTransferPath(int unused0, IntPtr device, IntPtr appUrl, IntPtr opts, IntPtr callback, int callback_arg);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceSecureInstallApplication(int unused0, IntPtr device, IntPtr appUrl, IntPtr opts, IntPtr callback, int callback_arg);
        [DllImport("iTunesMobileDevice.dll", CallingConvention = CallingConvention.Cdecl)]
        extern static int AMDeviceSecureUninstallApplication(int unused0, IntPtr device, IntPtr bundleId, int unused1, IntPtr callback, int callback_arg);

        public static bool StartService(IntPtr device, IntPtr service, out int sock)
        {
            return AMDeviceStartService(device, service, out sock) == NO_ERR;
        }

        public static Hashtable LookupApplication(IntPtr device)
        {
            IntPtr ptr = IntPtr.Zero;
            int b = AMDeviceLookupApplications(device, 0, out ptr);
            if ( b != NO_ERR )
            {
                return null;
            }
            int length = CFLibrary.CFDictionaryGetCount(ptr);
            IntPtr[] keys = new IntPtr[length];
            IntPtr[] values = new IntPtr[length];
            CFLibrary.CFDictionaryGetKeysAndValues(ptr, keys, values);

            Hashtable apps = new Hashtable();
            for ( int i = 0; i < length; i++ )
            {
                CFDictionary dict = new CFDictionary(values[i]);
                string bundle = dict.GetValue(CFBundleIdentifier).ToString();
                string type = dict.GetValue(ApplicationType).ToString();
                string name = dict.GetValue(CFBundleName).ToString();
                string displayname = dict.GetValue(CFBundleDisplayName).ToString();
                string version = dict.GetValue(CFBundleShortVersionString).ToString();
                string build = dict.GetValue(CFBundleVersion).ToString();
                Hashtable app = new Hashtable();
                app.Add(CFBundleIdentifier, bundle);
                app.Add(ApplicationType, type);
                app.Add(CFBundleName, name);
                app.Add(CFBundleDisplayName, displayname);
                app.Add(CFBundleShortVersionString, version);
                app.Add(CFBundleVersion, build);
                apps.Add(bundle, app);
            }
            return apps;
        }

        public static bool InstallApp(IntPtr device, string appPath)
        {
            CFString path = new CFString(appPath);
            IntPtr appUrl = CFLibrary.CFURLCreateWithFileSystemPath(IntPtr.Zero, path.typeRef, 2, false);
            string[] k = new string[1];
            k[0] = "PackageType";
            IntPtr[] v = new IntPtr[1];
            v[0] = new CFString("Developer");
            CFDictionary opts = new CFDictionary(k, v);

            int err = AMDeviceSecureTransferPath(0, device, appUrl, opts, IntPtr.Zero, 0);
            if ( err == NO_ERR )
            {
                return AMDeviceSecureInstallApplication(0, device, appUrl, opts, IntPtr.Zero, 0) == NO_ERR;
            }
            return err == NO_ERR;
        }

        public static bool UninstallApp(IntPtr device, string bundleId)
        {
            CFString appId = new CFString(bundleId);
            return AMDeviceSecureUninstallApplication(0, device, appId, 0, IntPtr.Zero, 0) == NO_ERR;
        }

        // Socket IO
        [DllImport("wsock32.dll", CallingConvention = CallingConvention.StdCall)]
        extern static int htonl(int length);
        [DllImport("wsock32.dll", CallingConvention = CallingConvention.StdCall)]
        extern static int ntohl(int length);
        [DllImport("wsock32.dll", CallingConvention = CallingConvention.StdCall)]
        extern static int send(int sfd, IntPtr buffer, int length, int flag);
        [DllImport("wsock32.dll", CallingConvention = CallingConvention.StdCall)]
        extern static int recv(int sfd, IntPtr buffer, int length, int flag);
        [DllImport("wsock32.dll", CallingConvention = CallingConvention.StdCall)]
        extern static int WSAGetLastError();

        public static byte[] SocketIO(int sfd, byte[] buffer)
        {
            int byteLength = 4;
            int wait = 250;

            if ( buffer.Length == 0 )
            {
                return null;
            }

            int err = 0;
            IntPtr ptr = IntPtr.Zero;
            byte[] he = new byte[byteLength];

            he = BitConverter.GetBytes(htonl(buffer.Length));
            ptr = Marshal.AllocHGlobal(byteLength);
            Marshal.Copy(he, 0, ptr, byteLength);
            err = send(sfd, ptr, byteLength, 0);
            Thread.Sleep(wait);
            Marshal.FreeHGlobal(ptr);
            err = WSAGetLastError();

            ptr = Marshal.AllocHGlobal(buffer.Length);
            Marshal.Copy(buffer, 0, ptr, buffer.Length);
            err = send(sfd, ptr, buffer.Length, 0);
            Thread.Sleep(wait);
            Marshal.FreeHGlobal(ptr);
            err = WSAGetLastError();

            ptr = Marshal.AllocHGlobal(byteLength);
            err = recv(sfd, ptr, byteLength, 0);
            Thread.Sleep(wait);
            Marshal.Copy(ptr, he, 0, byteLength);
            Marshal.FreeHGlobal(ptr);
            err = WSAGetLastError();

            int length = ntohl(BitConverter.ToInt32(he, 0));
            byte[] dest = new byte[length];
            ptr = Marshal.AllocHGlobal(length);
            err = recv(sfd, ptr, length, 0);
            Thread.Sleep(wait);
            Marshal.Copy(ptr, dest, 0, length);
            Marshal.FreeHGlobal(ptr);
            err = WSAGetLastError();

            return dest;
        }


        // Main Call

        public static int AttachiTunes()
        {
            if ( Environment.Is64BitProcess )
            {
                Console.Error.WriteLine("Running on 64bit mode");
            }
            else
            {
                Console.Error.WriteLine("Running on 32bit mode");
            }

            try
            {
                Process proc = new Process();
                proc.StartInfo.CreateNoWindow = true;
                proc.StartInfo.FileName = "cmd.exe";
                proc.StartInfo.UseShellExecute = false;
                proc.StartInfo.RedirectStandardError = true;
                proc.StartInfo.RedirectStandardInput = true;
                proc.StartInfo.RedirectStandardOutput = true;
                proc.Start();
                proc.StandardInput.WriteLine("taskkill /f /im iTunesHelper.exe");
                proc.Close();
            }
            catch ( Exception e )
            {
                Console.Error.WriteLine(e.Message);
            }

            string iTunesMobileDeviceDir = Registry.GetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\Apple Inc.\Apple Mobile Device Support", "InstallDir", Environment.CurrentDirectory).ToString();
            string ApplicationSupportDir = Registry.GetValue(@"HKEY_LOCAL_MACHINE\SOFTWARE\Apple Inc.\Apple Application Support", "InstallDir", Environment.CurrentDirectory).ToString();
            string iTunesMobileDeviceDLL = "iTunesMobileDevice.dll";

            FileInfo iTunesMobileDeviceFile = new FileInfo(iTunesMobileDeviceDir + iTunesMobileDeviceDLL);
            if ( !iTunesMobileDeviceFile.Exists )
            {
                Console.Error.WriteLine("Error iTunesMobileDevice.dll");
                return -1;
            }

            Environment.SetEnvironmentVariable("Path", string.Join(";", new string[] { Environment.GetEnvironmentVariable("Path"), iTunesMobileDeviceDir, ApplicationSupportDir }));

            return 0;
        }

        private static void usbMuxMode(ref AMDeviceNotificationCallbackInfo callback_info, uint cookie)
        {
            IntPtr devHandle = callback_info.dev;
            
            if ( devHandle == IntPtr.Zero )
            {
            	return;
            }

            AMDevice dev = new AMDevice(devHandle);

            if ( AMDeviceGetInterfaceType(devHandle) != DEVICE_INTERFACE_USB )
            {
                return;
            }

            if ( callback_info.msg == DEVICE_CONNECTED )
            {
                dev.WriteLine("Device Connected");
                Program.OnDeviceAttached(dev);
            }
            if ( callback_info.msg == DEVICE_DISCONNECTED )
            {
                dev.WriteLine("Device Disconnected");
            }
        }

        public static int InitDeviceAttachListener(int timeout)
        {
            IntPtr am_device_notification = IntPtr.Zero;
            AMDeviceNotificationSubscribe(usbMuxMode, 0, 0, 0, out am_device_notification);
            Thread.Sleep(timeout);
            AMDeviceNotificationUnsubscribe(am_device_notification);
            return 0;
        }

    }

}
