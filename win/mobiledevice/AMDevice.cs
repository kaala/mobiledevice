using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using CoreFoundation;
using ExtensionMethods;
using PlistCS;

namespace mobiledevice
{

    class AMDevice
    {
        IntPtr am_device;
        string deviceId;
        int socket_fd = 0;

        public AMDevice(IntPtr device)
        {
            am_device = device;
            deviceId = MobileDevice.GetDeviceIdentifier(device);
        }

        public void WriteLine(string msg)
        {
            Console.Out.WriteLine(deviceId + " " + msg);
            Console.Out.Flush();
        }

        public bool Connect()
        {
            return MobileDevice.Connect(am_device);
        }
        public bool Disconnect()
        {
            return MobileDevice.Disconnect(am_device);
        }

        public bool ValidatePairing()
        {
            if ( MobileDevice.IsPaired(am_device) )
            {
                return MobileDevice.ValidatePairing(am_device);
            }
            else
            {
                return MobileDevice.PairDevice(am_device);
            }
        }

        public bool StartSession()
        {
            return MobileDevice.StartSession(am_device);
        }
        public bool StopSession()
        {
            return MobileDevice.StopSession(am_device);
        }

        public const string SVC_INSTALLATION_PROXY = "com.apple.mobile.installation_proxy";
        public const string SVC_MCINSTALL = "com.apple.mobile.MCInstall";
        public const string SVC_DIAGNOSTICS_RELAY = "com.apple.mobile.diagnostics_relay";
        public const string SVC_MISAGENT = "com.apple.misagent";

        public bool StartService(string svc)
        {
            CFString c = new CFString(svc);
            return MobileDevice.StartService(am_device, c.typeRef, out socket_fd);
        }

        public Hashtable LookupApps()
        {
            bool direct = true;
            if ( direct )
            {
                return MobileDevice.LookupApplication(am_device);
            }

            if ( !StartService(SVC_INSTALLATION_PROXY) )
            {
                return null;
            }

            Dictionary<string, object> send = new Dictionary<string, object>
            {
                { "Command","Lookup" }
            };
            Dictionary<string, object> received = TransferPlist(send);
            Flush();

            Dictionary<string, object> lookup = received["LookupResult"] as Dictionary<string, object>;
            Dictionary<string, object>.KeyCollection keys = lookup.Keys;

            string CFBundleIdentifier = MobileDevice.CFBundleIdentifier;
            string ApplicationType = MobileDevice.ApplicationType;
            string CFBundleName = MobileDevice.CFBundleName;
            string CFBundleDisplayName = MobileDevice.CFBundleDisplayName;
            string CFBundleShortVersionString = MobileDevice.CFBundleShortVersionString;
            string CFBundleVersion = MobileDevice.CFBundleVersion;

            Hashtable apps = new Hashtable();
            foreach ( string key in keys )
            {
                Dictionary<string, object> v = lookup[key] as Dictionary<string, object>;
                string bundle = v.Find(CFBundleIdentifier) as string;
                string type = v.Find(ApplicationType) as string;
                string name = v.Find(CFBundleName) as string;
                string displayname = v.Find(CFBundleDisplayName) as string;
                string version = v.Find(CFBundleShortVersionString) as string;
                string build = v.Find(CFBundleVersion) as string;
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

        public void showApps(Hashtable apps)
        {
            string CFBundleIdentifier = MobileDevice.CFBundleIdentifier;
            string ApplicationType = MobileDevice.ApplicationType;
            string CFBundleName = MobileDevice.CFBundleName;
            string CFBundleDisplayName = MobileDevice.CFBundleDisplayName;
            string CFBundleShortVersionString = MobileDevice.CFBundleShortVersionString;
            string CFBundleVersion = MobileDevice.CFBundleVersion;

            foreach ( DictionaryEntry e in apps )
            {
                Hashtable app = e.Value as Hashtable;
                Console.Out.Write(app[CFBundleIdentifier]);
                Console.Out.Write("\t");
                Console.Out.Write(app[ApplicationType]);
                Console.Out.Write("\t");
                Console.Out.Write(app[CFBundleName]);
                Console.Out.Write(" ");
                Console.Out.Write(app[CFBundleShortVersionString]);
                Console.Out.Write("(");
                Console.Out.Write(app[CFBundleVersion]);
                Console.Out.Write(")");
                Console.Out.Write("\n");
            }
            Console.Out.Flush();
        }

        public bool InstallApp(string appPath)
        {
            FileInfo fd = new FileInfo(appPath);
            if ( !fd.Exists )
            {
                return false;
            }

            return MobileDevice.InstallApp(am_device, appPath);
        }

        public bool UninstallApp(string bundleId)
        {
            return MobileDevice.UninstallApp(am_device, bundleId);
        }

        Dictionary<string, object> TransferPlist(Dictionary<string, object> dict)
        {
            Dictionary<string, object> input = dict;
            byte[] source = Plist.writeBinary(input);
            byte[] dest = MobileDevice.SocketIO(socket_fd, source);
            Dictionary<string, object> output = Plist.readPlist(dest) as Dictionary<string, object>;
            return output;
        }

        public bool Flush()
        {
            Dictionary<string, object> dict = new Dictionary<string, object>
            {
                { "RequestType","Flush" }
            };
            Dictionary<string, object> received = TransferPlist(dict);
            return true;
        }

        public Hashtable LookupProfiles()
        {
            if ( !StartService(SVC_MCINSTALL) )
            {
                return null;
            }

            Dictionary<string, object> dict = new Dictionary<string, object>
            {
                { "RequestType","GetProfileList" }
            };
            Dictionary<string, object> received = TransferPlist(dict);
            Flush();

            string ProfileMetadata = MobileDevice.ProfileMetadata;
            string OrderedIdentifiers = MobileDevice.OrderedIdentifiers;
            string PayloadDisplayName = MobileDevice.PayloadDisplayName;
            string PayloadOrganization = MobileDevice.PayloadOrganization;
            string PayloadIdentifier = MobileDevice.PayloadIdentifier;

            List<object> keys = received[OrderedIdentifiers] as List<object>;
            int length = keys.Count;
            Dictionary<string, object> metas = received[ProfileMetadata] as Dictionary<string, object>;

            Hashtable profiles = new Hashtable();
            for ( int i = 0; i < length; i++ )
            {
                string identifier = keys[i] as string;
                Dictionary<string, object> meta = metas[identifier] as Dictionary<string, object>;
                string displayname = meta.Find(PayloadDisplayName) as string;
                string organization = meta.Find(PayloadOrganization) as string;
                Hashtable m = new Hashtable();
                m.Add(PayloadIdentifier, identifier);
                m.Add(PayloadDisplayName, displayname);
                m.Add(PayloadOrganization, organization);
                profiles.Add(identifier, m);
            }
            return profiles;
        }

        public void showProfiles(Hashtable profiles)
        {
            string ProfileMetadata = MobileDevice.ProfileMetadata;
            string OrderedIdentifiers = MobileDevice.OrderedIdentifiers;
            string PayloadDisplayName = MobileDevice.PayloadDisplayName;
            string PayloadOrganization = MobileDevice.PayloadOrganization;
            string PayloadIdentifier = MobileDevice.PayloadIdentifier;

            foreach ( DictionaryEntry e in profiles )
            {
                Hashtable app = e.Value as Hashtable;
                Console.Out.Write(app[PayloadIdentifier]);
                Console.Out.Write("\t");
                Console.Out.Write(app[PayloadDisplayName]);
                Console.Out.Write("(");
                Console.Out.Write(app[PayloadOrganization]);
                Console.Out.Write(")");
                Console.Out.Write("\n");
            }
            Console.Out.Flush();
        }

        public bool InstallProfile(string profilePath)
        {
            FileInfo fd = new FileInfo(profilePath);
            if ( !fd.Exists )
            {
                return false;
            }

            if ( !StartService(SVC_MCINSTALL) )
            {
                return false;
            }

            byte[] bytes = File.ReadAllBytes(profilePath);
            Dictionary<string, object> dict = new Dictionary<string, object>
            {
                { "RequestType","InstallProfile" },
                { "Payload",bytes },
            };

            Dictionary<string, object> received = TransferPlist(dict);
            string status = received["Status"] as string;
            Flush();

            return status.Equals("Acknowledged");
        }

        public bool UninstallProfile(string profileId)
        {
            if ( !StartService(SVC_MCINSTALL) )
            {
                return false;
            }

            Dictionary<string, object> dict = new Dictionary<string, object>
            {
                { "RequestType","RemoveProfile" },
                { "ProfileIdentifier",profileId },
            };
            Dictionary<string, object> received = TransferPlist(dict);
            string status = received["Status"] as string;
            Flush();

            return status.Equals("Acknowledged");
        }

        public bool Shutdown()
        {
            if ( !StartService(SVC_DIAGNOSTICS_RELAY) )
            {
                return false;
            }

            Dictionary<string, object> dict = new Dictionary<string, object>
            {
                { "Request","Shutdown" }
            };
            Dictionary<string, object> received = TransferPlist(dict);
            string status = received["Status"] as string;
            Flush();

            return status.Equals("Acknowledged");
        }

        public bool UpdateTime()
        {
            //DateTime dt = DateTime.Now;
            //DateTime ep = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
            //TimeSpan sp = dt.Subtract(ep);
            //double tk = sp.TotalSeconds;
            //return MobileDevice.updateTime(am_device, tk);

            //"com.apple.misagent",
            //"com.apple.mobile.diagnostics_relay",
            //"com.apple.mobile.MCInstall",
            //"com.apple.iosdiagnostics.relay",

            if ( !StartService(SVC_MISAGENT) )
            {
                return false;
            }

            DateTime dt = DateTime.Now;
            DateTime ep = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc);
            TimeSpan sp = dt.Subtract(ep);
            double tk = sp.TotalSeconds;
            Dictionary<string, object> dict = new Dictionary<string, object>
            {
                { "Request","SetValue" },
                { "Domain","NULL" },
                { "Key","TimeIntervalSince1970" },
                { "Value",tk }
            };
            Dictionary<string, object> received = TransferPlist(dict);
            string status = received["Status"].ToString();
            //Flush();

            return status.Equals("0");
        }

    }

}
