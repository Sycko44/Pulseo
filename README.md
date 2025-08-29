# Pulseo — PWA (déploiement Vercel)

Derniers correctifs appliqués
- ✅ Empêchement du rechargement lors de l’envoi d’un message
  - `index.html` : bouton d’envoi `type="button"` et `id="composer"`
  - `app.js` : `form.addEventListener('submit', e => e.preventDefault())` + gestion d’Enter
- ✅ (Recommandé) Forcer l’update du cache PWA : bump des noms de cache dans `service-worker.js`
  - `const PRECACHE = 'pulseo-precache-v3'`
  - `const RUNTIME  = 'pulseo-runtime-v3'`

## Déploiement sur Vercel
- **Framework Preset** : `Other`
- **Build Command** :
  - *(vide)* → version standard
  - `node check.js` → **si** on ajoute plus tard l’auto-correcteur Piratech
- **Output Directory** : *(vide)*

## Utilisation
1. Ouvrir l’URL du déploiement.
2. Aller jusqu’à l’écran “Discussion”.
3. Taper un message puis **Envoyer**.
   - Attendu : **reste sur la page**, le message apparaît dans le fil.

## En cas de comportement ancien (cache)
La PWA peut servir d’anciennes ressources.
- Bumper `service-worker.js` (voir ci-dessus), **commit**, attendre le redeploy.
- Sur le téléphone : Paramètres du site → Effacer données / ou onglet privé.
- Recharger la page.

## Checklist rapide
- `index.html` : bouton `type="button"` (pas de `submit` implicite)
- `app.js` : `preventDefault()` sur l’événement `submit`, gestion de la touche Enter
- `service-worker.js` : noms de cache à jour (`v3`, `v4`, …) si besoin de forcer l’update
- Vercel : dernier déploiement **Ready**