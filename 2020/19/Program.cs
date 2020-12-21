using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace day19
{
    public enum ParseStage
    {
        Rules,

        Messages
    }

    public class Rule
    {
        #region Fields

        public readonly int Id;

        #endregion

        #region Constructors

        public Rule(int id)
        {
            this.Id = id;
        }

        #endregion
    }

    public class CharacterRule : Rule
    {
        #region Fields

        public readonly char Character;

        #endregion

        #region Constructors

        public CharacterRule(int id,
                             char character)
            : base(id)
        {
            this.Character = character;
        }

        #endregion
    }

    public class IntermediateRule : Rule
    {
        #region Fields

        public readonly int[]? AltRuleSequence;

        public readonly int[] RuleSequence;

        #endregion

        #region Constructors

        public IntermediateRule(int id,
                                int[] ruleSequence)
            : base(id)
        {
            this.RuleSequence = ruleSequence;
            this.AltRuleSequence = null;
        }

        public IntermediateRule(int id,
                                int[] ruleSequence,
                                int[] altRuleSequence)
            : base(id)
        {
            this.RuleSequence = ruleSequence;
            this.AltRuleSequence = altRuleSequence;
        }

        #endregion
    }

    internal class Program
    {
        #region Class Methods

        private static void Main(string[] args)
        {
            if (args.Length != 1)
            {
                Console.WriteLine(@"Usage: .\day19 "".\path\to\input.txt""");
                return;
            }

            var parseStage = ParseStage.Rules;
            var rules = new Dictionary<int, Rule>();
            var messages = new List<string>();

            using var sr = new StreamReader(args[0]);

            while (!sr.EndOfStream)
            {
                var line = sr.ReadLine();

                if (line!.Length == 0)
                {
                    parseStage = ParseStage.Messages;
                    continue;
                }

                switch (parseStage)
                {
                    case ParseStage.Rules:
                        Rule rule = ParseRule(line);
                        rules[rule.Id] = rule;
                        break;
                    case ParseStage.Messages:
                        messages.Add(line);
                        break;
                }
            }

            var ruleRegex = GetRulesRegex(rules);

            Console.WriteLine(ruleRegex);

            var validMessages = 0;

            foreach(var message in messages)
            {
                if (ruleRegex.IsMatch(message))
                {
                    validMessages++;
                }
            }

            Console.WriteLine($"Valid messages: {validMessages}");
        }

        private static Rule ParseRule(string rawRule)
        {
            string[] ruleParts = rawRule.Split(':',
                                               '|')
                                        .Select(rulePart => rulePart.Trim())
                                        .ToArray();

            int ruleId = int.Parse(ruleParts[0]);
            int[] ruleSequence;

            switch(ruleParts[1])
            {
                case @"""a""":
                    return new CharacterRule(ruleId,
                                             'a');
                case @"""b""":
                    return new CharacterRule(ruleId,
                                             'b');
                default:
                    ruleSequence = ruleParts[1]
                                   .Split(' ')
                                   .Select(item => int.Parse(item))
                                   .ToArray();
                    break;
            }

            if(ruleParts.Length == 3)
            {
                int[] altRuleSequence = ruleParts[2]
                                        .Split(' ')
                                        .Select(item => int.Parse(item))
                                        .ToArray();
                return new IntermediateRule(ruleId,
                                            ruleSequence,
                                            altRuleSequence);
            }
            else
            {
                return new IntermediateRule(ruleId,
                                            ruleSequence);
            }
        }

        private static Regex GetRulesRegex(IDictionary<int, Rule> rules)
        {
            var regexBuilder = new StringBuilder();
            regexBuilder.Append('^');
            VisitRule(rules,
                      regexBuilder,
                      0);
            regexBuilder.Append('$');

            var regex = new Regex(regexBuilder.ToString());

            return regex;
        }

        private static void VisitRule(IDictionary<int, Rule> rules, StringBuilder regexBuilder, int ruleId)
        {
            var currentRule = rules[ruleId];

            if(currentRule is CharacterRule characterRule)
            {
                regexBuilder.Append(characterRule.Character);
                return;
            }
            else if(currentRule is IntermediateRule intermediateRule)
            {
                if(currentRule.Id == 8)
                {
                    VisitRule(rules,
                              regexBuilder,
                              42);
                    regexBuilder.Append("+");
                    return;
                }
                else if (currentRule.Id == 11)
                {
                    //Use balancing groups to require an equal number of rules 42 and 31 to match.
                    regexBuilder.Append("(?<r11>");

                    VisitRule(rules,
                              regexBuilder,
                              42);

                    regexBuilder.Append(")+(?<-r11>");

                    VisitRule(rules,
                              regexBuilder,
                              31);
                    regexBuilder.Append(")+");
                    return;
                }

                regexBuilder.Append('(');

                foreach(var rule in intermediateRule.RuleSequence)
                {
                    VisitRule(rules,
                              regexBuilder,
                              rule);
                }

                if(intermediateRule.AltRuleSequence != null)
                {
                    regexBuilder.Append("|");

                    foreach(var rule in intermediateRule.AltRuleSequence)
                    {
                        VisitRule(rules,
                                      regexBuilder,
                                      rule);
                    }
                }

                regexBuilder.Append(')');
            }
        }

        #endregion
    }
}