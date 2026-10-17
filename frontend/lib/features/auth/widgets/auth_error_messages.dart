/// Traduction de présentation des messages exposés par le provider existant.
abstract final class AuthErrorMessages {
  static const network = 'Connexion impossible. Vérifiez votre réseau.';
  static const server = 'Une erreur est survenue. Réessayez plus tard.';

  static bool isNetwork(String message) =>
      message.startsWith('Erreur réseau inattendue') ||
      message.startsWith('Impossible de joindre le serveur') ||
      message.startsWith('Le délai d’attente du serveur');

  static String display(String message) {
    if (isNetwork(message)) return network;
    if (message.startsWith('Erreur du serveur') ||
        message.startsWith('Une erreur est survenue (') ||
        message == 'Une erreur inattendue est survenue.') {
      return server;
    }
    return message;
  }

  static bool isInvalidCode(String message) =>
      message == 'Le code de validation est invalide ou expiré.' ||
      message == 'Code invalide ou expiré.';
}
