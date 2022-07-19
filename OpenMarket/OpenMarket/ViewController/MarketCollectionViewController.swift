//
//  File.swift
//  OpenMarket
//
//  Created by 주디, 재재 on 2022/07/15.
//

import UIKit

class MarketCollectionViewController: UICollectionViewController {
    enum Section: Hashable {
        case main
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    lazy var dataSource = makeListDataSource()
    private var items: [Item] = []
    private let sessionManager = URLSessionManager(session: URLSession.shared)
    
    
    let segmentedControl: UISegmentedControl = {
        let segmentedControl = UIKit.UISegmentedControl(items: ["LIST", "GRID"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentTintColor = .systemBlue
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.systemBlue], for: .normal)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.layer.borderColor = UIColor.systemBlue.cgColor
        segmentedControl.layer.borderWidth = 1.0
        return segmentedControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = createListLayout()
        receivePageData()
        navigationItem.titleView = segmentedControl
        segmentedControl.addTarget(self, action: #selector(indexChanged), for: .valueChanged)
    }

    @objc func indexChanged(segmentedControl: UISegmentedControl) {
        if segmentedControl.selectedSegmentIndex == 0 {
            collectionView.collectionViewLayout = createListLayout()
            dataSource = makeListDataSource()
            receivePageData()
        } else {
            collectionView.collectionViewLayout = createGridLayout()
            dataSource = makeGridDataSource()
            receivePageData()
        }
    }

    func createListLayout() -> UICollectionViewLayout {
        let estimatedHeight = CGFloat(60)
        let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(estimatedHeight))
        let item = NSCollectionLayoutItem(layoutSize: layoutSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: layoutSize,
                                                       subitem: item,
                                                       count: 1)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        section.interGroupSpacing = 1
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    func createGridLayout() -> UICollectionViewLayout {
        let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: layoutSize)
        let groupsize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .fractionalHeight(0.33))
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupsize,
                                                       subitem: item,
                                                       count: 2)
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension MarketCollectionViewController {
    func makeListDataSource() -> DataSource {
        let registration = UICollectionView.CellRegistration<MarketListCollectionViewCell, Item>.init { cell, indexPath, item in
            cell.nameLabel.text = item.productName
            cell.priceLabel.text = item.price
            
            self.sessionManager.receiveData(baseURL: item.productImage) { result in
                switch result {
                case .success(let data):
                    guard let imageData = UIImage(data: data) else { return }
                    
                    DispatchQueue.main.async {
                        cell.imageView.image = imageData
                    }
                case .failure(_):
                    print("서버 통신 실패")
                }
            }
        }
        
        return DataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
        }
    }
    
    func makeGridDataSource() -> DataSource {
        let registration = UICollectionView.CellRegistration<MarketGridCollectionViewCell, Item>.init { cell, indexPath, item in
            cell.nameLabel.text = item.productName
            cell.priceLabel.text = item.price
            cell.bargainPriceLabel.text = item.bargainPrice
            cell.stockLabel.text = "잔여수량 : " + item.stock
            
            self.sessionManager.receiveData(baseURL: item.productImage) { result in
                switch result {
                case .success(let data):
                    guard let imageData = UIImage(data: data) else { return }
                    
                    DispatchQueue.main.async {
                        cell.imageView.image = imageData
                    }
                case .failure(_):
                    print("서버 통신 실패")
                }
            }
        }
        
        return DataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
        }
    }
    
    func applySnapshots() {
        var itemSnapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        itemSnapshot.appendSections([.main])
        itemSnapshot.appendItems(items)
        dataSource.apply(itemSnapshot, animatingDifferences: false)
    }
    
    func receivePageData() {
        let subURL = SubURL().pageURL(number: 1, countOfItems: 20)

        sessionManager.receiveData(baseURL: subURL) { result in
            switch result {
            case .success(let data):
                guard let page = DataDecoder().decode(type: Page.self, data: data) else { return }
                
                self.items = page.pages.map {
                    Item(product: $0 )
                }
                
                DispatchQueue.main.async {
                    self.applySnapshots()
                }
            case .failure(_):
                print("서버 통신 실패")
            }
        }
    }
}
