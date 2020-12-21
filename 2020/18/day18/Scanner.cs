using System;
using System.Collections.Generic;
using System.Text;

using static day18.TokenType;

namespace day18
{
    public class Scanner
    {
        private int current;

        private int line = 1;

        private int start;

        private string source;
        private List<Token> tokens;

        public List<Token> Scan(string source)
        {
            this.source = source;
            this.tokens = new List<Token>();

            while(!this.IsAtEnd())
            {
                this.start = this.current;
                this.ScanToken();
            }

            this.tokens.Add(new Token(Eof,
                                 "",
                                 null));

            return tokens;
        }

        private void ScanToken()
        {
            char c = this.Advance();

            switch(c)
            {
                case '(':
                    this.AddToken(LeftParen);
                    break;
                case ')':
                    this.AddToken(RightParen);
                    break;
                case '+':
                    this.AddToken(Plus);
                    break;
                case '*':
                    this.AddToken(Star);
                    break;
                case ' ':
                case '\r':
                case '\t':
                    break;
                case '\n':
                    this.line++;
                    break;
                default:
                    if(this.IsDigit(c))
                    {
                        this.Number();
                        break;
                    }

                    throw new Exception($"Unexpected character {c} at line {this.line}");
            }
        }

        private void AddToken(TokenType tokenType)
        {
            this.tokens.Add(new Token(tokenType,
                                      this.source.Substring(this.start,
                                                            this.current - this.start),
                                      null));
        }

        private void AddToken(TokenType tokenType,
                              int value)
        {
            this.tokens.Add(new Token(tokenType,
                                      this.source.Substring(this.start,
                                                            this.current - this.start),
                                      value));
        }

        private char Advance()
        {
            this.current++;
            return this.source[this.current - 1];
        }

        private bool IsAtEnd() => this.current >= this.source.Length;

        private bool IsDigit(char c) => c >= '0' && c <= '9';

        private void Number()
        {
            while(this.IsDigit(this.Peek()))
            {
                this.Advance();
            }

            var sourceNumber = this.source.Substring(this.start,
                                                     this.current - this.start);
            var number = int.Parse(sourceNumber);
            var token = new Token(TokenType.Number,
                                  sourceNumber,
                                  number);
            this.tokens.Add(token);
        }

        private char Peek()
        {
            if(this.IsAtEnd())
            {
                return '\0';
            }

            return this.source[this.current];


        }
    }
}
