using System;

namespace day20
{
    public static class BitExtensions
    {
        #region Instance Methods

        public static int ToInt32(this bool[] bits)
        {
            int value = 0;
            for (int i = 0;
                 i < bits.Length;
                 i++)
            {
                if (bits[i])
                {
                    value += (int)Math.Pow(2,
                                           bits.Length - i - 1);
                }
            }

            return value;
        }

        #endregion
    }
}