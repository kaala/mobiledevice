using System;
using System.Collections;
using System.IO;
using System.Threading;

namespace mobiledevice
{
    class Task
    {
        AMDevice device = null;

        public Task(AMDevice device)
        {
            this.device = device;
        }

        void ListApps(AMDevice device)
        {
            Hashtable apps = device.LookupApps();
            device.showApps(apps);
        }
        void ListProfiles(AMDevice device)
        {
            Hashtable profiles = device.LookupProfiles();
            device.showProfiles(profiles);
        }

        void InstallApp(AMDevice device, string appPath)
        {
            FileInfo fd = new FileInfo(appPath);
            if ( !fd.Exists )
            {
                device.WriteLine("InstallApp file");
                return;
            }
            bool success = device.InstallApp(appPath);
            if ( success )
            {
                device.WriteLine("InstallApp success");
            }
            else
            {
                device.WriteLine("InstallApp fail");
            }
        }
        void UninstallApp(AMDevice device, string appId)
        {
            Hashtable apps = device.LookupApps();
            if ( !apps.ContainsKey(appId) )
            {
                device.WriteLine("UninstallApp skip");
                return;
            }
            bool success = device.UninstallApp(appId);
            if ( success )
            {
                device.WriteLine("UninstallApp success");
            }
            else
            {
                device.WriteLine("UninstallApp fail");
            }
        }

        void InstallProfile(AMDevice device, string profilePath)
        {
            FileInfo fd = new FileInfo(profilePath);
            if ( !fd.Exists )
            {
                device.WriteLine("InstallProfile file");
                return;
            }
            bool success = device.InstallProfile(profilePath);
            if ( success )
            {
                device.WriteLine("InstallProfile success");
            }
            else
            {
                device.WriteLine("InstallProfile fail");
            }
        }
        void UninstallProfile(AMDevice device, string profileId)
        {
            Hashtable profiles = device.LookupProfiles();
            if ( !profiles.ContainsKey(profileId) )
            {
                device.WriteLine("UninstallProfile skip");
                return;
            }
            bool success = device.UninstallProfile(profileId);
            if ( success )
            {
                device.WriteLine("UninstallProfile success");
            }
            else
            {
                device.WriteLine("UninstallProfile fail");
            }
        }

        void Shutdown(AMDevice device)
        {
            bool success = device.Shutdown();
            if ( success )
            {
                device.WriteLine("Shutdown success");
            }
            else
            {
                device.WriteLine("Shutdown fail");
            }
        }

        void UpdateTime(AMDevice device)
        {
            bool success = device.UpdateTime();
            if ( success )
            {
                device.WriteLine("Sync success");
            }
            else
            {
                device.WriteLine("Sync fail");
            }
        }

        public void Execute(string command, string param)
        {
            if ( param.EndsWith(".mobileconfig") )
            {
                if ( command.Equals("install") )
                {
                    command = "mcinstall";
                }
            }

            switch ( command )
            {
                case ("install"):
                    InstallApp(device, param);
                    break;
                case ("uninstall"):
                    UninstallApp(device, param);
                    break;
                case ("mcinstall"):
                    InstallProfile(device, param);
                    break;
                case ("mcuninstall"):
                    UninstallProfile(device, param);
                    break;
                case ("device"):
                    ListApps(device);
                    ListProfiles(device);
                    break;
                case ("shutdown"):
                    Shutdown(device);
                    break;
                case ("sleep"):
                    int sec = Convert.ToInt32(param);
                    Thread.Sleep(sec * 1000);
                    break;
                case ("sync"):
                    UpdateTime(device);
                    break;
                case ("list"):
                    if ( param.Equals("app") )
                    {
                        ListApps(device);
                    }
                    if ( param.Equals("profile") )
                    {
                        ListProfiles(device);
                    }
                    break;
                case ("deploy"):
                    FileInfo fp = new FileInfo(param);
                    if ( !fp.Exists )
                    {
                        device.WriteLine("BatchExecute file");
                        return;
                    }

                    string[] lines = File.ReadAllLines(param);
                    foreach ( string line in lines )
                    {
                        string root = Directory.GetCurrentDirectory();
                        DirectoryInfo dir = fp.Directory;
                        Directory.SetCurrentDirectory(dir.FullName);
                        string[] rows = line.Split(' ');
                        if ( rows.Length != 2 )
                        {
                            continue;
                        }
                        Task subtask = new Task(device);
                        string arg1 = rows[0] as string;
                        string arg2 = rows[1] as string;
                        subtask.Execute(arg1, arg2);
                        Directory.SetCurrentDirectory(root);
                    }
                    break;
                default:
                    device.WriteLine("NoExecute " + command);
                    break;
            }

        }

    }
}