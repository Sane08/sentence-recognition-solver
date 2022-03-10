defmodule SentenceRecognitionSolverTest do
	use ExUnit.Case
	doctest SentenceRecognitionSolver

	test "Teste 1" do
		grammar = {[{"S", "AA"}, {"S", "B"}, {"A", "Ab"}, {"AA", "aa"}, {"B", "Bb"}, {"B", "b"}, {"Abb", "BBB"}], "S"}
		assert SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "aabb")
		assert SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "b")
		assert SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "bbbbbbb")
		assert not SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "aaa")
	end

	test "Teste 2" do
		grammar = {[{"S", "A"}, {"A", "a"}], "S"}
		assert SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "a")
		assert not SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "aa")
	end

	test "Teste 3" do
		grammar = {[{"S", "aAS"}, {"S", "a"}, {"A", "SbA"}, {"A", "ba"}, {"A", "SS"}], "S"}
		assert SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "abaa")
		assert SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "aaaa")
		assert SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "abaabaa")
		assert SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "aababbaa")
		assert not SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "abbb")
		assert not SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "b")
		assert not SentenceRecognitionSolver.isSentenceOnGrammar(grammar, "bababa")
	end
end
