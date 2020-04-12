public with sharing class MyClass {

	public List<ApexClass> classes {get;set;}

	public MyClass() {
		classes = [Select Id, Name From ApexClass];
	}

}
