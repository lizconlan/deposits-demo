function(doc) {
    for (idx in doc.department) {
    	emit(doc.department[idx], doc);
    }
}