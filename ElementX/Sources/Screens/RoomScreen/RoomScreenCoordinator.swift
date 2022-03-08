//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct RoomScreenCoordinatorParameters {
    let roomProxy: RoomProxyProtocol
}

final class RoomScreenCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: RoomScreenCoordinatorParameters
    private let roomScreenHostingController: UIViewController
    private var roomScreenViewModel: RoomScreenViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((RoomScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    @available(iOS 14.0, *)
    init(parameters: RoomScreenCoordinatorParameters) {
        self.parameters = parameters
        
        let timelineProvider = RoomTimelineProvider(roomProxy: parameters.roomProxy)
        let timelineController = RoomTimelineController(timelineProvider: timelineProvider)
        
        let viewModel = RoomScreenViewModel(roomProxy: parameters.roomProxy, timelineController: timelineController)
        let view = RoomScreen(context: viewModel.context)
        roomScreenViewModel = viewModel
        roomScreenHostingController = UIHostingController(rootView: view)
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[RoomScreenCoordinator] did start.")
        roomScreenViewModel.completion = { [weak self] result in
            MXLog.debug("[RoomScreenCoordinator] RoomScreenViewModel did complete with result: \(result).")
            guard let self = self else { return }
            self.completion?(result)
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.roomScreenHostingController
    }
}
