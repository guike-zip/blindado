import Foundation

/// Handler padrão de uma Content Blocker Extension: devolve `blockerList.json` ao Safari.
/// Toda a lógica de bloqueio vive na lista de regras estática, não neste código (research.md #4).
final class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        guard let url = Bundle.main.url(forResource: "blockerList", withExtension: "json"),
              let attachment = NSItemProvider(contentsOf: url)
        else {
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let item = NSExtensionItem()
        item.attachments = [attachment]
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}
