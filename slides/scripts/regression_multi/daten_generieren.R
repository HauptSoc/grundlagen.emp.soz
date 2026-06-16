# ============================================================================
# DAG-basierte Datengenerierung für multivariate Regressionsszenarien
# ============================================================================

# 1. KONFUNDIERUNG: Z beeinflusst sowohl X als auch Y
#    Struktur: Z → X, Z → Y, direkter Effekt X → Y
#    Ohne Kontrolle: X und Y korreliert (teilweise wegen Z)
#    Mit Kontrolle für Z: Echter X-Effekt wird sichtbar
simulate_confounding_binary <- function(n = 150, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  # Confounder Z
  Z <- rbinom(n, size = 1, prob = 0.5)
  
  # X wird durch Confounder Z beeinflusst
  X <- 0.7 * Z + rnorm(n, mean = 0, sd = 0.7)
  
  # Y wird durch beide X und Z beeinflusst
  # Direkter Effekt von X: 1.0
  # Effekt von Z: 1.5 (unabhängig von X)
  Y <- 1.0 * X + 1.5 * Z + rnorm(n, mean = 0, sd = 0.8)
  
  data.frame(X = X, Y = Y, Z = factor(Z, labels = c("Z=0", "Z=1")))
}

# 2. MEDIATION: X beeinflusst Z, und Z beeinflusst Y
#    Struktur: X → Z → Y
#    Ohne Kontrolle: X und Y korreliert (Gesamteffekt: direkt + indirekt)
#    Mit Kontrolle für Z: Nur direkter Effekt bleibt (oder nur indirekter sichtbar)
simulate_mediation_binary <- function(n = 150, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  # Exposure X
  X <- rnorm(n, mean = 0, sd = 1)
  
  # Mediator Z wird durch X beeinflusst
  Z <- rbinom(n, size = 1, prob = plogis(0.8 * X))
  
  # Outcome Y wird durch Z und (schwach) durch X beeinflusst
  # Haupteffekt durch Mediation: 1.2
  # Direkter Effekt X → Y: 0.3 (schwach)
  Y <- 0.3 * X + 1.2 * Z + rnorm(n, mean = 0, sd = 0.8)
  
  data.frame(X = X, Y = Y, Z = factor(Z, labels = c("Z=0", "Z=1")))
}

# 3. SCHEINKORRELATION (Spurious): Z beeinflusst X und Y, aber X → Y nicht
#    Struktur: Z → X, Z → Y, kein direkter X-Y Effekt
#    Ohne Kontrolle: X und Y korreliert (wegen gemeinsamer Ursache Z)
#    Mit Kontrolle für Z: Korrelation verschwindet oder wird sehr schwach
simulate_spurious_binary <- function(n = 150, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  # Gemeinsame Ursache Z
  Z <- rbinom(n, size = 1, prob = 0.5)
  
  # X wird allein durch Z beeinflusst
  X <- 0.9 * Z + rnorm(n, mean = 0, sd = 0.6)
  
  # Y wird allein durch Z beeinflusst (nicht direkt durch X!)
  # Zusätzlicher zufälliger Effect für Realismus
  Y <- 1.1 * Z + rnorm(n, mean = 0, sd = 0.7) + rnorm(n, mean = 0, sd = 0.3)
  
  data.frame(X = X, Y = Y, Z = factor(Z, labels = c("Z=0", "Z=1")))
}

# 4. INTERAKTION: Der Effekt von X auf Y hängt vom Wert von Z ab
#    Struktur: Y = β₀ + β₁*X + β₂*Z + β₃*(X*Z)
#    Ohne Kontrolle: Gemischter Effekt (durchschnittlich über Z-Gruppen)
#    Mit Kontrolle für Z: Durchschnittlicher X-Effekt sichtbar (aber nicht stratifiziert)
simulate_interaction_binary <- function(n = 150, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  X <- rnorm(n, mean = 0, sd = 1)
  Z <- rbinom(n, size = 1, prob = 0.5)
  
  # Effekt von X auf Y hängt von Z ab
  # Wenn Z=0: Effekt von X ist schwach (0.4)
  # Wenn Z=1: Effekt von X ist stark (0.4 + 1.2 = 1.6)
  Y <- 0.4 * X + 0.8 * Z + 1.2 * X * Z + rnorm(n, mean = 0, sd = 0.8)
  
  data.frame(X = X, Y = Y, Z = factor(Z, labels = c("Z=0", "Z=1")))
}
