//
//  WikipediaSearchViewController.swift
//  Example
//
//  Created by Krunoslav Zaher on 2/21/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import UIKit
#if !RX_NO_MODULE
import RxSwift
import RxCocoa
#endif

class WikipediaSearchViewController: ViewController {
    @IBOutlet var searchBarContainer: UIView!
    
    private let searchController = UISearchController(searchResultsController: UITableViewController())
    
    private var resultsViewController: UITableViewController {
        return (self.searchController.searchResultsController as? UITableViewController)!
    }
    
    private var resultsTableView: UITableView {
        return self.resultsViewController.tableView!
    }

    private var searchBar: UISearchBar {
        return self.searchController.searchBar
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let searchBar = self.searchBar
        let searchBarContainer = self.searchBarContainer

        searchBarContainer?.addSubview(searchBar)
        searchBar.frame = (searchBarContainer?.bounds)!
        searchBar.autoresizingMask = .flexibleWidth

        resultsViewController.edgesForExtendedLayout = UIRectEdge()

        configureTableDataSource()
        configureKeyboardDismissesOnScroll()
        configureNavigateOnRowClick()
        configureActivityIndicatorsShow()
    }

    func configureTableDataSource() {
        resultsTableView.register(UINib(nibName: "WikipediaSearchCell", bundle: nil), forCellReuseIdentifier: "WikipediaSearchCell")
        
        resultsTableView.rowHeight = 194

        // This is for clarity only, don't use static dependencies
        let API = DefaultWikipediaAPI.sharedAPI

        resultsTableView.delegate = nil
        resultsTableView.dataSource = nil

        searchBar.rx.text
            .asDriver()
            .throttle(0.3)
            .distinctUntilChanged()
            .flatMapLatest { query in
                API.getSearchResults(query)
                    .retry(3)
                    .retryOnBecomesReachable([], reachabilityService: Dependencies.sharedDependencies.reachabilityService)
                    .startWith([]) // clears results on new search term
                    .asDriver(onErrorJustReturn: [])
            }
            .map { results in
                results.map(SearchResultViewModel.init)
            }
            .drive(resultsTableView.rx.items(cellIdentifier: "WikipediaSearchCell", cellType: WikipediaSearchCell.self)) { (_, viewModel, cell) in
                cell.viewModel = viewModel
            }
            .addDisposableTo(disposeBag)
    }

    func configureKeyboardDismissesOnScroll() {
        let searchBar = self.searchBar
        let searchController = self.searchController
        
        resultsTableView.rx.contentOffset
            .asDriver()
            .filter { _ -> Bool in
                return !searchController.isBeingPresented
            }
            .drive(onNext: { _ in
                if searchBar.isFirstResponder {
                    _ = searchBar.resignFirstResponder()
                }
            })
            .addDisposableTo(disposeBag)
    }

    func configureNavigateOnRowClick() {
        let wireframe = DefaultWireframe.sharedInstance

        resultsTableView.rx.modelSelected(SearchResultViewModel.self)
            .asDriver()
            .drive(onNext: { searchResult in
                wireframe.open(url:searchResult.searchResult.URL)
            })
            .addDisposableTo(disposeBag)
    }

    func configureActivityIndicatorsShow() {
        Driver.combineLatest(
            DefaultWikipediaAPI.sharedAPI.loadingWikipediaData,
            DefaultImageService.sharedImageService.loadingImage
        ) { $0 || $1 }
            .distinctUntilChanged()
            .drive(UIApplication.shared.rx.networkActivityIndicatorVisible)
            .addDisposableTo(disposeBag)
    }
}
