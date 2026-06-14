import 'package:ai_core/ai_core.dart';

/// Simple in-memory AiSecretStore for the example app.
///
/// Stores API keys in memory (not persisted). In a production app,
/// use flutter_secure_storage or similar OS-backed secure storage.
class InMemoryAiSecretStore implements AiSecretStore {
  final Map<String, String> _keys = {};

  @override
  Future<String?> getApiKey(String providerUuid) async {
    return _keys[providerUuid];
  }

  @override
  Future<void> setApiKey(String providerUuid, String apiKey) async {
    _keys[providerUuid] = apiKey;
  }

  @override
  Future<void> deleteApiKey(String providerUuid) async {
    _keys.remove(providerUuid);
  }
}
