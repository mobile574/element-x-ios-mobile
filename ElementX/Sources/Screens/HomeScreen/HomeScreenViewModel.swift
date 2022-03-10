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
import Combine
import Kingfisher

@available(iOS 14, *)
typealias HomeScreenViewModelType = StateStoreViewModel<HomeScreenViewState,
                                                        Never,
                                                        HomeScreenViewAction>
@available(iOS 14, *)
class HomeScreenViewModel: HomeScreenViewModelType, HomeScreenViewModelProtocol {
    
    private var roomUpdateListeners = Set<AnyCancellable>()
    private var roomList: [RoomProxyProtocol]? {
        didSet {
            self.state.isLoadingRooms = (roomList == nil)
        }
    }
    
    private let imageCache: ImageCache

    var completion: ((HomeScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(userDisplayName: String, imageCache: Kingfisher.ImageCache) {
        self.imageCache = imageCache
        super.init(initialViewState: HomeScreenViewState(userDisplayName: userDisplayName, isLoadingRooms: true))
    }
    
    // MARK: - Public
    
    override func process(viewAction: HomeScreenViewAction) {
        switch viewAction {
        case .logout:
            self.completion?(.logout)
        case .loadRoomData(let roomIdentifier):
            self.loadAvatarForRoomWithIdentifier(roomIdentifier)
            self.loadRoomDisplayNameForRoomWithIdentifier(roomIdentifier)
        case .loadUserAvatar:
            self.completion?(.loadUserAvatar)
        case .selectRoom(let roomIdentifier):
            self.completion?(.selectRoom(roomIdentifier: roomIdentifier))
        }
    }
    
    func updateWithRoomList(_ roomList: [RoomProxyProtocol]) {
        
        roomUpdateListeners.removeAll()
        
        self.roomList = roomList
        
        roomList.forEach({ roomProxy  in
            roomProxy.paginateBackwards(count: 1, callback: nil)
            roomProxy.callbacks.sink { [weak self] callback in
                switch callback {
                case .updatedLastMessage:
                    self?.updateRoomForProxy(roomProxy)
                default:
                    break
                }
            }
            .store(in: &roomUpdateListeners)
        })
        
        state.rooms = roomList.map { roomProxy in
            roomFromProxy(roomProxy)
        }
    }
    
    func updateWithUserAvatar(_ avatar: UIImage?) {
        self.state.userAvatar = avatar
    }
    
    // MARK: - Private
    
    private func loadAvatarForRoomWithIdentifier(_ roomIdentifier: String) {
        guard let room = roomList?.filter({ $0.id == roomIdentifier }).first,
              let cacheKey = room.avatarURL?.path else {
                  return
              }
        
        if imageCache.isCached(forKey: cacheKey) {
            imageCache.retrieveImage(forKey: cacheKey) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let value):
                    self.updateAvatar(value.image, forRoomWithIdentifier: roomIdentifier)
                case .failure(let error):
                    MXLog.error("Failed retrieving avatar from cache with error: \(error)")
                }
            }
            
            return
        }
        
        room.loadAvatar { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let avatar):
                guard let avatar = avatar else {
                    return
                }
                
                self.imageCache.store(avatar, forKey: cacheKey)
                self.updateAvatar(avatar, forRoomWithIdentifier: roomIdentifier)
            default:
                break
            }
        }
    }
    
    private func loadRoomDisplayNameForRoomWithIdentifier(_ roomIdentifier: String) {
        guard let room = roomList?.filter({ $0.id == roomIdentifier }).first else {
            return
        }
        
        room.loadDisplayName { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let displayName):
                self.updateDisplayName(displayName, forRoomWithIdentifier: roomIdentifier)
            default:
                break
            }
        }
    }
    
    private func updateDisplayName(_ displayName: String, forRoomWithIdentifier roomIdentifier: String) {
        guard let index = self.state.rooms.firstIndex(where: { $0.id == roomIdentifier }) else {
            return
        }
        
        self.state.rooms[index].displayName = displayName
    }
    
    private func updateAvatar(_ avatar: UIImage?, forRoomWithIdentifier roomIdentifier: String) {
        guard let index = self.state.rooms.firstIndex(where: { $0.id == roomIdentifier }) else {
            return
        }
        
        self.state.rooms[index].avatar = avatar
    }
    
    private func updateRoomForProxy(_ roomProxy: RoomProxyProtocol) {
        state.rooms.updateEach { room in
            if room.id != roomProxy.id {
                return
            }
            
            room = roomFromProxy(roomProxy)
        }
    }
    
    private func roomFromProxy(_ roomProxy: RoomProxyProtocol) -> HomeScreenRoom {
        HomeScreenRoom(id: roomProxy.id,
                       displayName: roomProxy.name,
                       topic: roomProxy.topic,
                       lastMessage: roomProxy.lastMessage,
                       isDirect: roomProxy.isDirect,
                       isEncrypted: roomProxy.isEncrypted)
    }
}
