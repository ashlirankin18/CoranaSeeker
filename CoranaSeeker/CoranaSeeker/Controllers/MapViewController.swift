//
//  MapViewController.swift
//  CoranaSeeker
//
//  Created by Ashli Rankin on 3/29/20.
//  Copyright © 2020 Ashli Rankin. All rights reserved.
//

import UIKit
import MapKit

/// `UIViewController` subclass which displays a map.
final class MapViewController: UIViewController {
    
    @IBOutlet private weak var countryDisplayMapView: MKMapView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    private lazy var networkHelper = NetworkHelper()
    
    private lazy var dataManager = DataManager(networkHelper: networkHelper)
    
    private lazy var locationManager = LocationManager()
    
    private lazy var transitionDelegate = CardPresentationManager()
    
    private var country: Country?
    
    private var countries = [Country]() {
        didSet {
            DispatchQueue.main.async {
                self.getCurrentyInfo(with: self.countries)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        retrieveCountries()
    }
    
    private func configureNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
    }
    
    private func getCurrentyInfo(with countries: [Country]) {
        guard let location = self.locationManager.userLocation else {
            return
        }
        
        self.locationManager.getPlace(for: location) { [weak self] (placemark) in
            guard let countryName = placemark?.country else {
                return
            }
            
            if countryName == "United States" {
                let name = "US"
                if let currentCountry = self?.countries.first(where: { $0.name == name }) {
                    self?.country = currentCountry
                    self?.addAndShowAnnotation(lattitude: location.coordinate.latitude, longitude: location.coordinate.longitude, countryName: countryName)
                }
            }
        }
    }
    
    private func retrieveCoranaCasesStatistices(countryCode: String, status: String) {
        dataManager.retrieveCountryStatistics(urlEndPointString: "https://api.covid19api.com/total/country/\(countryCode)/status/\(status)") { [weak self] (result) in
            switch result {
            case let .success(cases):
                guard let newCase = cases.last else {
                    return
                }
                DispatchQueue.main.async {
                    self?.presentDetailledController(with: newCase)
                }
            case let .failure(error):
                print(error)
            }
        }
    }
    
    private func presentDetailledController(with countryCase: CountryCase) {
        let detailledController = CaseDetailViewController(countryCase: countryCase)
        detailledController.transitioningDelegate = transitionDelegate
        detailledController.modalPresentationStyle = .custom
        transitionDelegate.presentationDirection = .bottom
        present(detailledController, animated: true)
    }
    
    private func retrieveCountries() {
        dataManager.retrieveCountries(urlEndPointString: "https://api.covid19api.com/countries") { (result) in
            switch result {
            case let .failure(error):
                print(error)
            case let .success(countries):
                self.countries = countries
            }
        }
    }
    
    private func getLocation(countryName: String) {
        locationManager.getLocation(forPlaceCalled: countryName) { [weak self] (location) in
            if let location = location?.coordinate {
                self?.addAndShowAnnotation(lattitude: location.latitude, longitude: location.longitude, countryName: countryName)
            }
        }
    }
    
    private func addAndShowAnnotation(lattitude: CLLocationDegrees, longitude: CLLocationDegrees, countryName: String) {
        let locationAnnotation = MKPointAnnotation()
        locationAnnotation.coordinate = CLLocationCoordinate2D(latitude: lattitude, longitude: longitude)
        locationAnnotation.isAccessibilityElement = true
        locationAnnotation.title = countryName
        countryDisplayMapView.addAnnotation(locationAnnotation)
        countryDisplayMapView.showAnnotations([locationAnnotation], animated: true)
        countryDisplayMapView.centerCoordinate =  CLLocationCoordinate2D(latitude: lattitude, longitude: longitude)
        countryDisplayMapView.camera.altitude = 500_000
        
    }
    
    @IBAction func listButtonTapped(_ sender: UIBarButtonItem) {
        let listViewController = CountryListViewController(countries: countries)
        listViewController.transitioningDelegate = transitionDelegate
        listViewController.modalPresentationStyle = .custom
        listViewController.delegate = self
        present(listViewController, animated: true)
    }
    
    @IBAction private func confirmButtonTapped(_ sender: UIButton) {
        if let country = country {
            self.retrieveCoranaCasesStatistices(countryCode: country.slug, status: "confirmed")
        }
    }
    
    @IBAction private func deathsButtonTapped(_ sender: UIButton) {
        if let country = country {
            self.retrieveCoranaCasesStatistices(countryCode: country.slug, status: "deaths")
        }
    }
    
    @IBAction private func recoveredButtonTapped(_ sender: UIButton) {
        if let country = country {
            self.retrieveCoranaCasesStatistices(countryCode: country.slug, status: "recovered")
        }
    }
}

extension MapViewController: CountryListViewControllerDelegate {
  
    // MARK : - CountryListViewControllerDelegate
    
    func didSelectCountry(countryListViewController: CountryListViewController, country: Country) {
        getLocation(countryName: country.name)
        self.country = country
    }
}
