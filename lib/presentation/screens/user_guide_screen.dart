import 'package:flutter/material.dart';

class UserGuideScreen extends StatelessWidget{
  const UserGuideScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Korisničko uputstvo')),
    body:ListView(padding:const EdgeInsets.all(20),children:const[
      Text('Kako koristiti aplikaciju',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
      SizedBox(height:8),Text('Aplikacija je namenjena vežbanju fizike za I razred gimnazije. U njoj su dostupne oblasti i teme koje su do sada obrađene.'),
      _Guide('Vežbaj','Pokreće mešovito vežbanje iz obrađenog gradiva. Aplikacija uključuje i teorijska i računska pitanja. Kada postoji dovoljno podataka o tvom radu, prednost dobijaju oblasti u kojima je potrebno dodatno vežbanje.'),
      _Guide('Personalizuj vežbanje','Prvo biraš sve obrađene oblasti ili jednu od glavnih oblasti, na primer Uvod u fiziku ili Kinematiku. Glavnu oblast možeš proširiti i izabrati samo pojedinačne teme koje želiš da vežbaš. Zatim izaberi Mešovito, Računski ili Teorijski i broj pitanja.'),
      _Guide('Formativna provera časa','Izaberi obrađenu nastavnu celinu. Dobijaš kratku proveru od 5 do 8 pitanja. Posle svakog odgovora odmah vidiš da li je odgovor tačan i dobijaš kratko objašnjenje. Rezultat služi za učenje i ne predstavlja školsku ocenu.'),
      _Guide('Test','Aplikacija sastavlja test od 16 pitanja iz svih trenutno obrađenih oblasti: 8 osnovnog, 5 srednjeg i 3 naprednog nivoa, uz kombinovanje teorijskih i računskih zadataka i različitih prikaza. Neobrađeno gradivo se ne pojavljuje u testu.'),
      _Guide('Moj napredak','Prikazuje napredak po oblastima na osnovu pokušaja sa ovog uređaja. Ako aplikacija prepozna oblast kojoj treba dodatno vežbanje, možeš izabrati „Vežbaj ovu oblast“. Podaci se u ovoj verziji čuvaju lokalno na uređaju i nisu vezani za učenički nalog.'),
      _Guide('Grafici, tabele i šeme','Neka pitanja sadrže grafički prikaz, tabelu ili šemu. Pažljivo pročitaj oznake i podatke na prikazu pre nego što izabereš odgovor.'),
      _Guide('Povratna informacija','Posle odgovora prikazuju se tačan odgovor i objašnjenje. Koristi objašnjenje da proveriš postupak, a zatim nastavi na sledeće pitanje. Kvizove i vežbanja možeš ponavljati.'),
      _Guide('Ažuriranje sadržaja','Aplikacija može da dobije novu odobrenu bazu pitanja bez ponovne instalacije. Ako nema interneta ili ažuriranje ne uspe, nastavlja da koristi poslednju ispravnu bazu sa uređaja.'),
      _Guide('Važno','Aplikacija je u ovoj verziji namenjena vežbanju i samoproveri. Nema učeničke naloge i ne koristi se kao zvanični elektronski kontrolni zadatak.'),
    ]),
  );
}
class _Guide extends StatelessWidget{
  const _Guide(this.title,this.body);final String title,body;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(body)]));
}
