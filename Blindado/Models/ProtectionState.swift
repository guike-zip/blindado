import Foundation

/// Estado real da proteção no sistema — **nunca persistido**, sempre recalculado a partir de
/// `NEDNSSettingsManager` ao entrar em primeiro plano (`scenePhase`), conforme Constitution
/// Princípio IV (Honestidade com o Usuário).
enum ProtectionState: Equatable, Sendable {
    /// Nenhum perfil de DNS foi instalado ainda.
    case naoConfigurado
    /// Perfil instalado, porém não ativado pelo usuário em Ajustes (ou desativado manualmente
    /// fora do app).
    case instaladoDesativado
    /// Perfil instalado e ativo (`NEDNSSettingsManager.isEnabled == true`).
    case blindado
}
