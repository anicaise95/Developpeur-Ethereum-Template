Dans le contrat Voting, on considère que : 
- le gagnant est la proposition qui obtient le plus de voix. S'il y a égalité, il y aura 2 gagnants.
- au moins 2 propositions pour pouvoir voter, une même proposition ne peut pas être ajoutée 2 fois pour ne pas fausser les votes 


------------------------------------------------------------------------------------------------------------------
CAS DE TEST (en attendant les TU :))
Exemple de sondage : La plus belle ville de France

L'adminstrateur (qui déploie le contrat contrat) : 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum
	Electeur 1 (admin) : 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
	Electeur 2 : 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
	Electeur 3 : 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
	Electeur 4 : 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

L'administrateur du vote commence la session d'enregistrement de la proposition.

Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.

	Electeur 1 : Marseille, Aix, Bordeaux
	Electeur 2 : Lacanau, Aix, Montpellier, Nice
  Electeur 3 : 
	Electeur 4 : Strasbourg

L'administrateur de vote met fin à la session d'enregistrement des propositions.

L'administrateur du vote commence la session de vote.

--> Voir la liste des propositions après saisie : 
	uint256)[] : 
		Marseille,0,
		Aix,0,
		Bordeaux,0,
		Lacanau,0,
		Montpellier,0,
		Nice,0,
		Strasbourg,0

Les électeurs inscrits votent pour leur proposition préférée.
Saisir la position de la proposition préférée dans la liste en commancant de 0
	Vote électeur 1 : 1 --> (Aix)
	Vote électeur 2 : 5 --> (Nice)
	Vote électeur 3 : 5 --> (Nice)
	Vote électeur 4 : 1 --> (Aix)

--> Voir la liste des propositions avec les votes : 
	Marseille,0,
	Aix,2,
	Bordeaux,0,
	Lacanau,0,
	Montpellier,0,
	Nice,2,
	Strasbourg,0

L'administrateur du vote met fin à la session de vote.

L'administrateur du vote comptabilise les votes.

Tout le monde peut vérifier les derniers détails de la proposition gagnante ou des gagants en cas d'égalité.
Résultats : Aix,2,Nice,2

Ici une égalité dans les résultats du sondage
