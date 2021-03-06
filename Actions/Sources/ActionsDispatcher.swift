//
//  ActionsDispatcher.swift
//  Actions
//
//  Created by Dariusz Grzeszczak on 29/01/2018.
//  Copyright © 2018 Dariusz Grzeszczak. All rights reserved.
//

public protocol SyncActionsDispatcher {
    func dispatch<Act: Action>(action: Act) -> Act.ReturnType
}

public protocol AsyncActionsDispatcher {
    func dispatch<Act: AsyncAction>(action: Act, completion: @escaping (Act.ReturnType) -> Void)
}

public final class ActionsDispatcher: SyncActionsDispatcher, AsyncActionsDispatcher {
    private var handlers: [String: Any] =  [:]
    var actions: [String] {
        return handlers.map { $0.key }
    }

    public let routingEnabled: Bool
    public init(routingEnabled: Bool = true) {
        self.routingEnabled = routingEnabled
        guard routingEnabled else { return }
        ActionsRouter.instance.add(dispatcher: self)
    }

    private func add(handler: Any, for actionID: String) {
        if routingEnabled && ActionsRouter.instance.contains(actionID: actionID) {
            fatalError("Doubled action: \(actionID). The same Action cannot be handled by two different handlers.")
        }
        handlers[actionID] = handler
    }

    public func register<Act: Action>(action: Act.Type, handler: @escaping (Act.ParamType) -> Act.ReturnType) {
        add(handler: handler, for: Act.actionID)
    }

    public func dispatch<Act: Action>(action: Act) -> Act.ReturnType {
        guard let handler = handlers[type(of: action).actionID] as? ((Act.ParamType) -> Act.ReturnType) else {
            fatalError("Unsuported action")
        }

        return handler(action.param)
    }

    public func register<Act: AsyncAction>(action: Act.Type, handler: @escaping (Act.ParamType, _ completion: @escaping (Act.ReturnType) -> Void) -> Void) {
        add(handler: handler, for: Act.actionID)
    }

    public func register<Act: AsyncAction>(action: Act.Type,
                                           handler: @escaping (_ completion: @escaping (Act.ReturnType) -> Void) -> Void)
        where Act.ParamType == Void {

            let finalHandler: (Act.ParamType, _ completion:  @escaping (Act.ReturnType) -> Void) -> Void = { _, completion in handler(completion)
            }
            add(handler: finalHandler, for: Act.actionID)
    }

    public func dispatch<Act: AsyncAction>(action: Act, completion: @escaping (Act.ReturnType) -> Void) {
        guard let handler = handlers[type(of: action).actionID] as? ((Act.ParamType, _ completion: @escaping (Act.ReturnType) -> Void) -> Void) else {
            fatalError("Unsuported action")
        }

        handler(action.param, completion)
    }
}
