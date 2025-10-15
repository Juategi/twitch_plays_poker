import 'package:dart_openai/dart_openai.dart';
import 'dart:convert';

class LLM_AI {
  static Future<Map<String, dynamic>> pedirDecisionIA(
    Map<String, dynamic> estado,
  ) async {
    List<OpenAIModelModel> models = await OpenAI.instance.model.list();
    for (var model in models) {
      print('Modelo disponible: ${model.id} - ${model.toString()}');
    }

    OpenAICompletionModel completion = await OpenAI.instance.completion.create(
      model: "gpt-3.5-turbo-0125",
      prompt: "Dart is a program",
      maxTokens: 20,
      temperature: 0.5,
      n: 1,
      stop: ["\n"],
      echo: true,
      seed: 42,
      bestOf: 2,
    );

    final contenido = completion.choices.first.text;
    print('Respuesta de la IA: $contenido');
    return {};
  }
}
