using System.Collections.Generic;

namespace ExtensionMethods
{
    public static class ExtensionMethods
    {
        public static object Find(this Dictionary<string, object> dict, string key)
        {
            if ( dict.ContainsKey(key) )
            {
                return dict[key];
            }
            else
            {
                return null;
            }
        }
    }
}