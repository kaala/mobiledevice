using System;
using System.Collections;
using System.IO;
using System.Threading;
using mobiledevice;

class Program
{

    static Hashtable inArgs = null;

    public static int Main(string[] args)
    {
        if ( MobileDevice.AttachiTunes() == -1 )
        {
            return -1;
        }

        // 拖放自动部署文件时
        if ( args.Length == 1 )
        {
            string file = args[0] as string;
            FileInfo fp = new FileInfo(file);
            if ( fp.Exists )
            {
                args = new string[] { "deploy", file };
            }
        }

        // 用法说明
        if ( args.Length != 2 )
        {
            Console.Error.WriteLine("available commands: list | deploy | install | uninstall | mcinstall | mcuninstall");
            Console.Error.WriteLine(string.Join(" ", args));
            Thread.Sleep(3000);
            return 0;
        }

        // 参数解析
        Program.inArgs = new Hashtable();
        string cmd = args[0] as string;
        string param = args[1] as string;
        Program.inArgs.Add("command", cmd.ToLower());
        Program.inArgs.Add("param", param);

        // 调整设备连接通知持续时间
        // TODO: Thread结束会强制终止程序，强制timeout=-1
        int timeout = -1;
        if ( cmd.Equals("deploy") )
        {
            timeout = -1;
        }
        MobileDevice.InitDeviceAttachListener(timeout);

        return 0;
    }

    public static bool OnDeviceAttached(AMDevice device)
    {
        // 捕捉所有异常
        try
        {
            return Run(device);
        }
        catch ( Exception e )
        {
            device.WriteLine(e.Message);
            return false;
        }
    }

    public static bool Run(AMDevice device)
    {
        if ( !device.Connect() )
        {
            device.WriteLine("Connect error");
            return false;
        }
        if ( !device.ValidatePairing() )
        {
            device.WriteLine("Pairing error");
            device.Disconnect();
            return false;
        }
        if ( !device.StartSession() )
        {
            device.WriteLine("Session error");
            device.Disconnect();
            return false;
        }

        Hashtable args = Program.inArgs;
        string ca = args["command"] as string;
        string pa = args["param"] as string;
        Task task = new Task(device);
        task.Execute(ca, pa);

        device.StopSession();
        device.Disconnect();

        device.WriteLine("Execute success");
        return true;
    }
}

