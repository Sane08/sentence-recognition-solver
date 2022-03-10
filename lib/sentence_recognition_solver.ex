defmodule SentenceRecognitionSolver do
  # Searches for a sentence in the list
  def checkGrammarList(list, sentence) do
    cond do
      sentence == hd(list) -> true
      length(list) > 1 -> checkGrammarList(tl(list), sentence)
      true -> false
    end
  end

  # Transforms the grammar rules list into a MapSet
  def mapGrammarRules(grammar_rules, mapped_grammar_rules \\ %{}) do
    case length(grammar_rules) > 0 do
      true ->
        {alpha, beta} = hd(grammar_rules)
        mapped_grammar_rules = Map.get_and_update(mapped_grammar_rules, alpha, fn(mapset_rules) ->
          {mapset_rules, case Map.fetch(mapped_grammar_rules, alpha) do
            :error -> MapSet.new([beta])
            _ -> MapSet.put(mapset_rules, beta)
          end}
        end) |> elem(1)
        mapGrammarRules(tl(grammar_rules), mapped_grammar_rules)
      _ -> mapped_grammar_rules
    end
  end

  # Makes single-symbol-based substitutions
  # e.g. S --> aa
  def substituteSymbols(sentence, symbol_rules, new_sentence_array, max_size, index) do
    case length(symbol_rules) > 0 do
      true ->
        new_sentence_splitted = List.replace_at(sentence, index, hd(symbol_rules))
        new_sentence = Enum.join(new_sentence_splitted, "")
        case String.length(new_sentence) <= max_size do
          true -> substituteSymbols(sentence, tl(symbol_rules), new_sentence_array ++ [new_sentence], max_size, index)
          _ -> substituteSymbols(sentence, tl(symbol_rules), new_sentence_array, max_size, index)
        end
      _ -> new_sentence_array
    end
  end

  # Makes multiple-symbol-based substitutions
  # e.g. SS --> aa
  def substituteBigSymbols(symbols_already_analyzed, rest, symbol_rules, new_sentence_array, max_size) do
    case length(symbol_rules) > 0 do
      true ->
        new_sentence = symbols_already_analyzed <> hd(symbol_rules) <> rest
        case String.length(new_sentence) <= max_size do
          true -> substituteBigSymbols(symbols_already_analyzed, rest, tl(symbol_rules), new_sentence_array ++ [new_sentence], max_size)
          _ -> substituteBigSymbols(symbols_already_analyzed, rest, tl(symbol_rules), new_sentence_array, max_size)
        end
      _ -> new_sentence_array
    end
  end

  # Finds sets of multiple symbols that can be substituted according to mapped_rules
  def loopOnSymbolsLength(mapped_rules, symbols, max_size, symbols_size \\ 2, index \\ 0, new_sentences_array \\ []) do
    case length(symbols) > 1 do
      true ->
        sentence = Enum.join(symbols, "")
        {symbols_already_analyzed, other_symbols} = String.split_at(sentence, index)
        {symbol_to_be_analyzed, rest} = String.split_at(other_symbols, symbols_size)
        case Map.has_key?(mapped_rules, symbol_to_be_analyzed) do
          true -> symbol_rules = Map.get(mapped_rules, symbol_to_be_analyzed) |> MapSet.to_list
                  new_sentence_array = substituteBigSymbols(symbols_already_analyzed, rest, symbol_rules, new_sentences_array, max_size)
                  cond do
                    length(symbols) > index + symbols_size -> loopOnSymbolsLength(mapped_rules, symbols, max_size, symbols_size, index + 1, new_sentence_array)
                    length(symbols) > symbols_size -> loopOnSymbolsLength(mapped_rules, symbols, max_size, symbols_size + 1, 0, new_sentence_array)
                    true -> new_sentence_array
                  end
          _ -> cond do
                length(symbols) > index + symbols_size -> loopOnSymbolsLength(mapped_rules, symbols, max_size, symbols_size, index + 1, new_sentences_array)
                length(symbols) > symbols_size -> loopOnSymbolsLength(mapped_rules, symbols, max_size, symbols_size + 1, 0, new_sentences_array)
                true -> new_sentences_array
              end
        end
        _ -> []
    end
  end

  # Applies the grammar rules to create an array of possible sentences
  def useGrammarRulesOnSentence(mapped_rules, symbols, max_size, new_sentences_array \\ [], index \\ 0) do
    new_big_sentences = loopOnSymbolsLength(mapped_rules, symbols, max_size)
    new_sentences_array = new_sentences_array ++ new_big_sentences
    symbol_to_be_substituted = Enum.at(symbols, index)
    case Map.has_key?(mapped_rules, symbol_to_be_substituted) do
      true -> symbol_rules = Map.get(mapped_rules, symbol_to_be_substituted) |> MapSet.to_list
              new_sentence_array = substituteSymbols(symbols, symbol_rules, new_sentences_array, max_size, index)
              case length(symbols) > index + 1 do
                true -> useGrammarRulesOnSentence(mapped_rules, symbols, max_size, new_sentence_array, index + 1)
                _ -> new_sentence_array
              end
      _ -> case length(symbols) > index + 1 do
            true -> useGrammarRulesOnSentence(mapped_rules, symbols, max_size, new_sentences_array, index + 1)
            _ -> new_sentences_array
           end
    end
  end

  # Manages array-based calls to useGrammarRulesOnSentence
  def useGrammarRulesOnSentencesArray(sentences_array, mapped_rules, max_size, index \\ 0, new_sentences \\ []) do
    sentence_to_use_rule = Enum.at(sentences_array, index)
    symbols = String.split(sentence_to_use_rule, "", trim: true)
    new_sentences_array = useGrammarRulesOnSentence(mapped_rules, symbols, max_size)
    case length(sentences_array) > index + 1 do
      true -> useGrammarRulesOnSentencesArray(sentences_array, mapped_rules, max_size, index + 1, new_sentences ++ new_sentences_array)
      _ -> case Enum.sort(Enum.uniq(sentences_array ++ new_sentences ++ new_sentences_array)) == Enum.sort(sentences_array) do
        false -> useGrammarRulesOnSentencesArray(Enum.uniq(sentences_array ++ new_sentences ++ new_sentences_array), mapped_rules, max_size)
        _ -> sentences_array
      end
    end
  end

  # Generates a complete list of sentences formed with grammar_rules
  # limited by max_size characters
  def sentenceGenerator(grammar_rules, max_size, initial_sentence) do
    mapped_rules = mapGrammarRules(grammar_rules)
    symbols = String.split(initial_sentence, "", trim: true)
    sentences_array = useGrammarRulesOnSentence(mapped_rules, symbols, max_size)
    useGrammarRulesOnSentencesArray(sentences_array, mapped_rules, max_size)
  end

  # Determines whether sentence can be formed by grammar or not
  def isSentenceOnGrammar(grammar, sentence) do
    {grammar_rules, initial_sentence} = grammar
    max_size = String.length(sentence)
    list_of_sentences_on_grammar = sentenceGenerator(grammar_rules, max_size, initial_sentence)
    checkGrammarList(list_of_sentences_on_grammar, sentence)
  end
end
