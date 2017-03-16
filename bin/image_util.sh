function getImageName {
	image_number=$1

	case "$image_number" in
	"1")
  	  echo $image_one 
   	 ;;
	"2")
  	  echo $image_two
  	  ;;
	"3")
  	  echo $image_three
  	  ;;
	"4")
  	  echo $image_four
  	  ;;  	
	"5")
  	  echo $image_five
  	  ;;  	
	"6")
  	  echo $image_six
  	  ;;  	
	"7")
  	  echo $image_seven
  	  ;;  	
	"8")
  	  echo $image_eight
  	  ;; 
	"9")
  	  echo $image_nine
  	  ;; 
	"10")
  	  echo $image_ten
  	  ;;   	    	   	  	    	    	    	      	  
	*)
   	  echo "nothing"
  	  ;;
	esac
}
