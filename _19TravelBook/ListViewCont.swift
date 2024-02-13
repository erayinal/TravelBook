//
//  ListViewCont.swift
//  _19TravelBook
//
//  Created by Eray İnal on 31.01.2024.
//

import UIKit
import CoreData //21 Şimdi bu CoreData'dan çektiğimiz verileri tableView'da gstermemiz lazım bu yüzden CoreData import ettik.

class ListViewCont: UIViewController, UITableViewDelegate, UITableViewDataSource {
    

    //18 Bu class'ı oluşturduktan sonra Main'e gidip bu sınıfı yeni eklediğimiz ViewController ile eşleştirelim, tableView da ekleyelim sonrasında seuge ekleyip isimlerini verip geri dönebilmek için Navigation Controller da koyalım
    
    @IBOutlet weak var tableView: UITableView!
    
    
    var titleArray = [String]()
    var idArray = [UUID]()  //...21 Bunlaru oluşturduktan sonra şimdi fonksşyonda kaldığımız yerden devam edelim
    
    var chosenTitle = ""
    var chosenTitleID : UUID? //..26 şimdi addButtonClicked fonksiyonuna gidelim
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked)) //.20 Şimdi bir tane selector methodu oluşturalım
        
        //19 TableView ayarlarını yapalım hızlıca:
        tableView.delegate = self
        tableView.dataSource = self //.19 bunları yazınca hata vericek UITableViewDelegate UITableViewDataSource import etmediğimiz içim. Bunları yazınca da hata vericek çünkü o interface'lerın zorunlu methodlarını yazmadık(numberOfRowSection, cellForRowAt)
        
        //24 her şeyden sonra gelip bu getData donksiyonunu burada yazmazsak bir işe yaramaz:
        getData()

    }
    
    //.32 bu fonksiyonla birlikte tableView'ı güncel tutabiliyoruz
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    
    
    //.21 Şimdi fonksiyon oluşturalım
    @objc func getData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(request)
            if (results.count>0){
                
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)      //.22 temizledik
                
                for elem in results as! [NSManagedObject]{
                    
                    if let title = elem.value(forKey: "title") as? String{
                        //..21 Bunları yazmadan önce sınıfın başına gidip array şeklinde title ve id'leri tutan array'lar tanımlayalım
                        self.titleArray.append(title)
                    }
                    if let id = elem.value(forKey: "id") as? UUID{
                        self.idArray.append(id) //22 tabi bunları yazdık ama for döngüsüne girmeden önce bunları temizlememiz lazım ki duplice veriler olmasın bu yüzden for'dan önce temizleyelim
                    }
                    
                    tableView.reloadData()
                    
                    //23 Bunları yazdıktan sonra gidip tableView için açtığımız iki fonksiyon içeriğini düzeltelim
                }
            }
        }catch{
            print("error")
        }
        
        
    }
    
    @objc func addButtonClicked(){
        chosenTitle = ""  //...26 burada bunu boş olarak ayarladık. Alt satırdaki kod önceden vardı dokunmadık. Şimdi fonksiyonlarımıza dönebiliriz
        performSegue(withIdentifier: "toViewController"  , sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return 10  //.23 öncesinde geçici olsun diye return 10 yazmıştık şimdi düzeltelim:
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        //cell.textLabel?.text = "test" //..23 öncesinde geçiçi olsun diye bu şekilde yazmıştık ama şimdi düzeltelim:
        cell.textLabel?.text = titleArray[indexPath.row]
        
        return cell
        //20 bu iki methodu yazdıktan sonra viewDidLoad içerisine dönelim ve sol üste 'artı(+)' butonu koyalım
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //.26 Şimdi yine bunları doldurmadan önce bu sınıfın başında iki tane değişken tanımlayalım
        
        chosenTitle = titleArray[indexPath.row]
        chosenTitleID = idArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toViewController"){
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = chosenTitle
            destinationVC.selectedTitleID = chosenTitleID //27 işte bu iki fonksiyon sayesinde buradakileri diğer tarafa aktarabiliyoruz. İşte şimdi ViewController sınıfına gidip oradaki iki fonksiyonu dolduralım
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
      if (editingStyle == .delete) {
          let appDelegate = UIApplication.shared.delegate as! AppDelegate
          let context = appDelegate.persistentContainer.viewContext
          
          let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
          
          let idString = idArray[indexPath.row].uuidString
          fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
          
          fetchRequest.returnsObjectsAsFaults = false
          
          do{
              let results = try context.fetch(fetchRequest)
              
              if(results.count>0){
                  
                  for elem in results as! [NSManagedObject]{
                      if let id = elem.value(forKey: "id") as? UUID{
                          if (id == idArray[indexPath.row]){
                              context.delete(elem)
                              titleArray.remove(at: indexPath.row)
                              idArray.remove(at: indexPath.row)
                              self.tableView.reloadData()
                              
                              do{
                                  try context.save()
                              }catch{
                                  print("Error!!")
                              }
                              
                              break     // Silmek istediğimiz şey silindiğinde bu loop bitecek
                          }
                      }
                      
                  }
                  
              }
          }catch{
              print("Error!")
          }
      }
    }
    

}
