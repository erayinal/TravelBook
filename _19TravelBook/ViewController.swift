//
//  ViewController.swift
//  _19TravelBook
//
//  Created by Eray İnal on 19.01.2024.
//

import UIKit
import MapKit   //.1
import CoreLocation //..2
import CoreData //..13

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView! //1 Bunu yazdığımızda swift bize hata verecek, Bu hatayı düzeltmek için: 1)import Mapkit , 2)MKMapViewDelegate ile interface çağırmam lazım , 3) viewDidLoad içerisinde delegate etmem lazım
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField! //.12 Bunları tanımladıktan sonra gidip chooseLocation methodunda Title ve Subtitle'ı değiştirelim
    
    var locationManager = CLLocationManager() //...2 kullanıcı konumuyla alakalı bir şey yapıyorsak CLLocation çağırmamız lazım. Şimdi bunu bir de delegate etmemiz lazım onun için CLLocationManagerDelegate interface çağırmamız ve delegate etmeliyiz
    
    var chosenLatitude = Double()
    var chosenLongitude = Double() //.15 Şimdi gidip chooseLocation methodu içerisinde bunlara değerlerini verelim
    
    //25:
    var selectedTitle = ""
    var selectedTitleID : UUID?
    
    //28:
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self //..1 ve şuan hata son buldu ve bu haliyle kodu çalıştırdığımızda karşımıza bir harita çıkacak ve hareket, zoom dahi yapılabilir. Ama kullanıcı konumunu açmıyor sadece genel bir harita gösteriyor.Kullanıcının konumunu almamız lazım //2 Kullanıcı konumunu nasıl alıcaz...
        //.2 kullanıcı konumunu almak için öncelikle CoreLocation'ı import etmemiz lazım sonra locationManager oluşturmamız lazım
        
        locationManager.delegate = self //....2
        
        //3 Şimdi bu konumun ne kadar keskin olduğunu bildirmemiz lazım, yani kullanıcının konumunu ne kadar ayrıntılı alıcaz, oturma odasında oturduğunu dahi gösterecek miyiz onu belirliyicez
        locationManager.desiredAccuracy = kCLLocationAccuracyBest//.3 Yazığı gibi best şekilde konumu alır ama çok şarj yer, çok pil yemesin istiyorsak kCLLocationAccuracyKilometer kullanırız ve 1 kilometrelik sapmalarla konumu verir.
        
        //4 Şimdi kullanıcıdan izin istememiz gerekiyor:
        locationManager.requestWhenInUseAuthorization() //.4 Bu şekilde uygulamayı kullanırken konumu alırız, istersek bunu requestAlwaysAuthorization yaparak uygulama kapalıyken de alabiliriz ama genelde her zaman kullanmak için çok mantıklı sebeplerimiz olmaz bu yüzden uygulama kullanılırken olacak şekilde izin isteriz 
        //..4 Bir de onay alırken çıkan pop-up ekrana açıklama koymak lazım, onun için 'Info' sayfasına gidip 'Privacy-Locaiton When in Used' seçeneği ile yapıyoruz
        
        //5 Kullanıcının izin verdiğini düşünerek devam ediyoruz:
        locationManager.startUpdatingLocation() //.5 Kullanıcının konumunu bu kelimeyle birlikte almaya başlıyoruz.
        
        //6 Şimdi biz kullanıcıdan konum aldık ama onunla ne yapacağımızı falan daha belirlemedik, bunun için bir fonksiyon var onu yazmalıyız -> DidUpdateLocation yazınca çıkacak, şimdi gidip onu yazalım:
        
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:))) //.7normalde UITab yapıyorduk burada ise uzun basmasını sağlıyoruz, bunun için şimdi selector fonsiyonu yazalım
        
        gestureRecognizer.minimumPressDuration = 2 //.9 Burada kaç saniye basması gerektiğini belirttik. En az 2 saniye basması gerekecek, genelde 2 veya 3 kullanılır. //10Şimdi chooseLocation fonsktinonuna geri gidip fonksiyon içeriğini yazalım:
        mapView.addGestureRecognizer(gestureRecognizer) //.8 Burada mapView içerisine bu gestureRecognizer'ı koyduk fakat //9 bunu koymadan önce kaç saniye basması gerektiğini de belirtebiliriz
        
        
        if(selectedTitle != ""){ //.25 seçilen title boş değilse CoreData'dan veri çekme işlemini yapıcaz
            //26 bu methodu doldurmadan önce ListViewCont sınıfına gidip orada iki fonksiyon yazmamız lazım
            
            //.27:
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedTitleID!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                if(results.count > 0){
                    
                    for elem in results as! [NSManagedObject]{
                        //28 Şimdi bu for'u doldurmadan önce sınıfın başına gidip değişkenler oluşturalım
                        if let title = elem.value(forKey: "title") as? String{
                            annotationTitle = title
                            
                            if let subtitle = elem.value(forKey: "subtitle") as? String{
                                annotationSubtitle = subtitle
                                
                                if let latitude = elem.value(forKey: "latitude") as? Double{
                                    annotationLatitude = latitude
                                    
                                    if let longitude = elem.value(forKey: "longitude") as? Double{
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation() //29 bu sayede konum değişse de harita değişmeyecek ve biz bakmak istediğimiz yerde kalabilicez. Yani biz önceden kaydettiğimiz bir yere bakarken cihazımızla konum değişirse harita hareket edicekti onun önüne geçtik
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                        
                                    }
                                }
                            }
                        }
                        
                    }
                }
                
            }catch{
                print("Error...")
            }
            
        }else{ //..25 Boş ise bir şey yapmamıza gerek yok.
            
        }
        
    }
    
    @objc func chooseLocation(gestureRecognizer : UILongPressGestureRecognizer){ //..7 'gestureReconizer:UILongPressGestureRecognizer' şeklinde parametre ile yazıp bu fonksiyonu selector içerisinde çağırırsak bu parametrenin özelliklerine ulaşabileceğiz. //8 Şimdi viewDidLoad İçerisine geri dönelim
        
        //.10 Önceki adımları hallettikten sonra şimdi fonksiyon içeriğini belirtmemiz lazım. Burada uzun tıkladıktan sonra tıklanılan yerin kordinatlarını almak istiyorum: Önce gestureRecgonizer başladı mı başlamadı mı onu kontrol edicem:
        if(gestureRecognizer.state == .began) { //..10 başladıysa dokunulan noktayı alıcaz
            let touchedPoint = gestureRecognizer.location(in: self.mapView) //...10 Dokunulan noktanın locationunu aldık şimdi bunu kordinata çevirmemiz gerekiyor
            let touchedCoordinate = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) //....10 Noktanın kordinatlarını aldık peki pin'i nasıl oluşturucaz:
            
            chosenLatitude = touchedCoordinate.latitude
            chosenLongitude = touchedCoordinate.longitude //..15 bu iki satır kodu yazmaktan başka methodda değişiklik falan yapmıyoruz. Şimdi saveButton içerisine geri dönelim
            
            let annotation = MKPointAnnotation()    //11 Burada pin'i oluşturuduk ama konumunu belirlemedik, şimdi konumunu da belirleyelim:
            annotation.coordinate = touchedCoordinate
            annotation.title = nameText.text //.11 Başlık verebiliriz
            annotation.subtitle = commentText.text  //..11Altyazı verebiliriz
            self.mapView.addAnnotation(annotation) //...11 en sonda bu annotationu mapView'a ekleyince olay bitiyor
            
            //12 Şimdi gidip main'de iki tane Text Field ekleyelim sonrasında bu label'ları bu class'da tanımlayalım
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if(selectedTitle == ""){ //30 buraya bir if ekleyelim ki sync şekilde çalışsın:
            
            //.6 Bu fonksiyon bana güncellenen locaitonları CLLocation şeklinde bir dizi içerisinde veriyor bana. CLLocation enlem ve boylam veren bir obje. Şimdi örnek olsun diye bir enlem boylam verip bu konuma zoomlamasını sağlıyıcam, sonra bu satırı yorum satırına alıp fonksiyonu asıl olmaıs gereken hale getiricez:
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) //..6 konumunu aldık ve şimdi de zoom seviyesi ayarlayalım: Zoom seviyesine 'Span' deniyor
            let span = MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04) //...6 Bu ne kadar küçükse o kadar yakın oluyor
            let region = MKCoordinateRegion(center: location, span: span) // burada merkezi belirlediğimiz konum yapıyoruz, zoom seviyesini de span olarak belirliyoruz
            mapView.setRegion(region, animated: true) //....6 işimiz bitti. Bu fonksiyonda sadece kullnıcıdan konum almamıza gerek yok biz kendimiz de konum verebiliriz
            
            //7 Şimdi gelelim pinleme olayına, bu uygulamada kullınıcı gidip belirtmek istediği yeri pinleyecek. Bunu nasıl yapıcaz: gestureRecognizer ile, şimdi gidip viewDidLoad içerisinde bunu yapalım
            
        }
        
        
    }
    
    //13 Şimdi Save diye bir buton koyup onu bu class'da tanımlayalım
    @IBAction func saveButton(_ sender: Any) {
        //.13 Bu methodu doldurmadan önce gidip localDatamıza 'Places' adında bir entity açalım ve attributes'ları dolduralım. Attribute'lar içerisnde title, subtitle ve konum olacak, peki konumu nasıl tutucaz? -> enlem ve boylam olarak ve bunlar int değil double.
        //..13 Şimdi methodu yazmaya başlamadan önce CoreData'yı import edelim. Sonrasında önce appDelegate falan yapıp kayıt edicez bunları zaten biliyoruz
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context) //14 Burada forEntityName ismi Entity ismi ile aynı olmalı
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle") //.14 Bunları yapmadan önce aslında if ile title ve subtitle doldurulmuş mu bunu kontrol edip boşsa alert göndermemiz lazımdı ama şimdilik geçiyoruz
        //15 Peki enlem ve boylamı nasıl alıcaz. Aslında bunlar chooseLocation methodu içerisinde var, sadece bunlara ulaşmak lazım, onun için önce o method dışında class içerisinde method tanımlayalım ve methodda sonra onu ayarlayalım ki onu burada da kullanabilelim
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        
        //16 en sonda id'yi yapalım:
        newPlace.setValue(UUID(), forKey: "id") //.16 en son olarak da context.save yapmamız laızm ama bunu do-catch içerisinde yapmamız lazım:
        do{
            try context.save()
            print("success")
        }catch{
            print("Error")
        }
        
        //17 şimdi main'da yeni bir viewController açalım ve ok işaretini ona kaydıralım ki uygulama açılışında ilk o açılsın
        
        
        //31 Şimdi uygulamanın bazı eksikleri var onları halledelim; mesela bir yer kaydettiğimizde tableView'a direkt olarak gitmiyor uygulamayı tekrar açmamız gerekiyor, bunun önüne geçmek adına 'SAVE' butonuna basınca tableView'a sayfasına geri gelsin ve güncellesin:
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil) //.31 bu satır bütün app'e bir mesaj yolluyor sonra diğer tarafta bir observer kullanarak bu 'newPlace' mesajı gelince ne yapacağımızı söyleyebiliyoruz
        navigationController?.popViewController(animated: true) //..31 Bu satırdaki kod çalışınca bir önceki viewController'a(ListViewCont) bizi atacak yani tableView olan sayfaya
        
        //32 Şimdi ListViewCont'a gidip observer kullanarak 'newPlace' mesajı gelince ne yapacağımızı söyleyelim:
        
    }
    
    
    //33 Bir başka istediğimiz şey ise, kaydettiğimiz yere yol tarifi ile gidebilmek:
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if(annotation is MKUserLocation){
            return nil
        }
        
        let reuseID = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if(pinView == nil){
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true //.33 Bu satır ile pin yanında bir baloncukla ekstra bilgi gösterebildiğimiz yer
            pinView?.tintColor = UIColor.black // pinlerin rengini de değiştirebiliriz
            
            //..33 Şimdi konum hakkındaki bilgilerin olduğu baloncuk içerisinde bir buton ekleyelim ki ona tıklanınca yol tarifi yapabilsin
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }
        else{
            pinView?.annotation = annotation
        }
        
        return pinView
        
        //34 Buraya kadar her şey tamam şimdi butona basınca yol tarifi için Apple Haritalar'a gitsin. Bunun için hemen bu fonksiyonun altında bir fonksiyon yazalım
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //.34 Bu kodun amacı o baluncaktaki butona basıldığını algılamak. Basılınca bu fonksyion çağrılacak
        
        if(selectedTitle != ""){
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                
                if let placemark = placemarks{
                    if(placemark.count > 0){
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving] //..34 Burada ARABA ile yol tarifi seçtik
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
        }
    }
    
    
    
    
    
    

}

