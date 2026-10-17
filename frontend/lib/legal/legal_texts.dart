/// Textes de démonstration à faire valider avant toute mise en production.
abstract final class LegalTexts {
  static const termsTitle = "Conditions d'utilisation";
  static const privacyTitle = 'Politique de confidentialité';

  static const terms = '''
Version de démonstration
Ces conditions constituent un exemple pour le prototype pédagogique TRILL Covoit'. Elles devront être adaptées et validées avant l'ouverture d'un service réel.

1. Objet du service
TRILL Covoit' permet de mettre en relation des personnes souhaitant partager leurs trajets du quotidien. Chaque utilisateur reste libre de proposer ou d'accepter un trajet. La disponibilité d'un conducteur ou d'une place n'est pas garantie.

2. Création du compte
Vous devez fournir une adresse email personnelle valide et choisir un mot de passe confidentiel. La validation de votre adresse email est nécessaire pour accéder à l'application. Vous êtes responsable de la protection de vos identifiants et devez signaler toute utilisation non autorisée.

3. Engagements des utilisateurs
Les informations communiquées doivent être exactes. Les échanges doivent rester respectueux, sans discrimination ni harcèlement. Le conducteur doit disposer d'un permis valide, d'un véhicule en état de circuler et d'une assurance adaptée. Tous les participants doivent respecter le code de la route et les horaires convenus.

4. Annulation et sécurité
Prévenez les autres participants dès que possible en cas d'annulation. Ne publiez pas d'informations sensibles dans les échanges. En cas de danger immédiat, contactez les services d'urgence ; l'application ne remplace pas leur assistance.

5. Responsabilité et évolution
Le service facilite la mise en relation et n'organise pas un transport professionnel. Les obligations de chacun et les modalités d'un éventuel partage de frais devront être précisées avant la mise en production. Les utilisateurs seront informés des modifications importantes de ces conditions.
''';

  static const privacy = '''
Information sur le traitement des données personnelles
Ce texte est un exemple destiné au prototype pédagogique. L'identité et les coordonnées du responsable de traitement, les durées définitives de conservation et le contact pour exercer vos droits devront être précisés avant la mise en production.

1. Données concernées
L'inscription utilise votre adresse email, votre mot de passe et votre acceptation des conditions. Le serveur conserve une empreinte du mot de passe, et non sa valeur en clair. Un code temporaire permet de vérifier votre adresse email. Les fonctionnalités de trajet pourront nécessiter des données de départ, d'arrivée et d'horaire, selon leur disponibilité.

2. Finalités et bases légales
Ces données servent à créer votre compte, vérifier votre email, vous authentifier et assurer le fonctionnement du service. La gestion du compte repose sur l'exécution du service demandé ; les mesures de sécurité peuvent relever de l'intérêt légitime, sous réserve de l'analyse applicable. Accepter les conditions ne constitue pas un consentement à des usages publicitaires.

3. Destinataires
L'accès aux données doit être limité aux personnes habilitées et aux prestataires nécessaires à l'hébergement et à l'envoi des emails. Seules les informations utiles à l'organisation d'un trajet ont vocation à être partagées avec ses participants. Les prestataires et les éventuels transferts hors de l'Union européenne devront être documentés.

4. Conservation et sécurité
Les données doivent être conservées uniquement pendant la durée nécessaire aux finalités annoncées, puis supprimées ou anonymisées, sous réserve des obligations légales. Les codes de vérification sont temporaires. Des mesures techniques et organisationnelles doivent protéger les accès et les échanges.

5. Vos droits
Selon les conditions prévues par le RGPD, vous pouvez demander l'accès, la rectification, l'effacement ou la portabilité de vos données, ainsi que la limitation du traitement ou vous y opposer. Un canal de contact opérationnel devra être communiqué avant le lancement. Vous pouvez également adresser une réclamation à la CNIL.
''';
}
