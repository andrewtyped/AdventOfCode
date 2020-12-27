using System;
using System.Collections.Generic;
using System.Text;

namespace day20
{
    public class TileParser
    {
        #region Instance Methods

        public Tile Parse(IList<string> rawTile)
        {
            if (rawTile.Count < 1)
            {
                throw new InvalidOperationException("Tile must have an id");
            }

            int tileId = this.GetTileId(rawTile[0]);
            bool[][] rows = this.GetTileRows(rawTile);

            return new Tile(tileId,
                            rows);
        }

        private int GetTileId(string rawTileId)
        {
            var tileIdBuilder = new StringBuilder();

            foreach (var character in rawTileId)
            {
                if (character >= '0'
                    && character <= '9')
                {
                    tileIdBuilder.Append(character);
                }
            }

            return int.Parse(tileIdBuilder.ToString());
        }

        private bool[][] GetTileRows(IList<string> rawTile)
        {
            var rows = new bool[rawTile.Count - 1][];

            for (int i = 1;
                 i < rawTile.Count;
                 i++)
            {
                var rawRow = rawTile[i];
                var row = new bool[rawRow.Length];
                rows[i - 1] = row;

                for (int column = 0;
                     column < rawRow.Length;
                     column++)
                {
                    row[column] = rawRow[column] == '#';
                }
            }

            return rows;
        }

        #endregion
    }
}